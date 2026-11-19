import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../../core/ids.dart';

/// Profile photos (private `avatars` bucket). The server decides who may read what; anything a viewer cannot read
/// simply yields null so the UI falls back to initials.
abstract class AvatarRepository {
  /// Photo bytes of [userId] if one exists and the signed-in user may see it; otherwise null. Never throws.
  Future<Uint8List?> photoOf(String userId);

  /// Photo bytes at a known storage [path] (the own profile's `avatar_path`); null on any failure. Never throws.
  Future<Uint8List?> photoAt(String path);

  /// Uploads [jpeg] as a NEW object, lets the server validate it and switch the pointer, and returns the new path.
  Future<String> save(Uint8List jpeg);

  /// Clears the pointer and deletes the user's photo objects.
  Future<void> remove();

  /// Drops every cached path and photo (sign-out, account switch).
  void clear();
}

/// Used where photos are not wired (tests, previews): every avatar is initials.
class NoAvatarRepository implements AvatarRepository {
  const NoAvatarRepository();
  @override
  Future<Uint8List?> photoOf(String userId) async => null;
  @override
  Future<Uint8List?> photoAt(String path) async => null;
  @override
  Future<String> save(Uint8List jpeg) =>
      Future.error(UnsupportedError('Avatars are not available here.'));
  @override
  Future<void> remove() async {}
  @override
  void clear() {}
}

class SupabaseAvatarRepository implements AvatarRepository {
  SupabaseAvatarRepository(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _uid = _client.auth.currentUser?.id;
    _sub = _client.auth.onAuthStateChange.listen((s) {
      final id = s.session?.user.id;
      if (id != _uid) {
        _uid = id;
        clear(); // nothing of one account's photos may survive into the next
      }
    });
  }

  static const _bucket = 'avatars';
  static const _pathTtl = Duration(seconds: 60);
  static const _maxPhotos = 100;

  final SupabaseClient _client;
  final DateTime Function() _now;
  // ignore: unused_field
  late final StreamSubscription<AuthState> _sub;
  String? _uid;

  // Path lookup: one batched profiles query per tick; RLS decides whose avatar_path is visible.
  final _paths = <String, ({String? path, DateTime at})>{};
  final _waiting = <String, List<Completer<String?>>>{};
  Timer? _timer;

  // Bytes: a path never changes content (each upload is a new path), so they are cached per path.
  final _photos = <String, Future<Uint8List?>>{};

  @override
  Future<Uint8List?> photoOf(String userId) async {
    try {
      final path = await _path(userId);
      return path == null ? null : await photoAt(path);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _path(String userId) {
    final hit = _paths[userId];
    if (hit != null && _now().difference(hit.at) < _pathTtl) {
      return Future.value(hit.path);
    }
    final c = Completer<String?>();
    (_waiting[userId] ??= []).add(c);
    _timer ??= Timer(const Duration(milliseconds: 15), _flush);
    return c.future;
  }

  Future<void> _flush() async {
    final batch = Map.of(_waiting);
    _waiting.clear();
    _timer = null;
    try {
      final rows = await _client
          .from('profiles')
          .select('id, avatar_path')
          .inFilter('id', batch.keys.toList());
      final found = {
        for (final r in rows) r['id'] as String: r['avatar_path'] as String?,
      };
      for (final e in batch.entries) {
        final p = found[e.key];
        _paths[e.key] = (path: p, at: _now());
        for (final c in e.value) {
          c.complete(p);
        }
      }
    } catch (_) {
      for (final cs in batch.values) {
        for (final c in cs) {
          c.complete(null); // initials; the next render retries
        }
      }
    }
  }

  @override
  Future<Uint8List?> photoAt(String path) {
    var f = _photos[path];
    if (f == null) {
      if (_photos.length >= _maxPhotos) _photos.remove(_photos.keys.first);
      // A unique query value: Cloudflare otherwise answers a repeat GET of the same URL and token from its cache even after
      // the object was deleted or access was revoked (measured on DEV), skipping the database check.
      f = _client.storage
          .from(_bucket)
          .download(path, queryParams: {'cb': newRequestId()})
          .then<Uint8List?>((b) => b, onError: (_) => null);
      _photos[path] = f;
      f.then((b) {
        if (b == null) _photos.remove(path); // do not cache a failure
      });
    }
    return f;
  }

  @override
  Future<String> save(Uint8List jpeg) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppError(
        AppErrorKind.unknown,
        'You are not signed in.',
        AppErrorCode.notSignedIn,
      );
    }
    final path = '$uid/${newRequestId()}.jpg';
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            jpeg,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
              cacheControl: '60',
            ),
          );
    } catch (e) {
      throw AppError.from(e);
    }
    try {
      final r = await _client.rpc('set_my_avatar', params: {'p_path': path});
      _paths.remove(uid);
      unawaited(_deleteStale(r));
      return path;
    } catch (e) {
      await _deleteStale({
        'stale': [path],
      }); // do not leave an unreferenced object behind
      throw AppError.from(e);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final r = await _client.rpc('remove_my_avatar');
      _paths.remove(_client.auth.currentUser?.id);
      unawaited(_deleteStale(r));
    } catch (e) {
      throw AppError.from(e);
    }
  }

  Future<void> _deleteStale(Object? result) async {
    final stale = result is Map && result['stale'] is List
        ? [for (final p in result['stale'] as List) p as String]
        : const <String>[];
    if (stale.isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove(stale);
    } catch (_) {
      // The next save/remove reports any leftovers again.
    }
  }

  @override
  void clear() {
    _paths.clear();
    _photos.clear();
    for (final cs in _waiting.values) {
      for (final c in cs) {
        c.complete(null);
      }
    }
    _waiting.clear();
    _timer?.cancel();
    _timer = null;
  }
}
