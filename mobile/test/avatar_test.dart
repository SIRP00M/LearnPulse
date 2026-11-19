import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/avatar_image.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/profile/avatar_repository.dart';
import 'package:learn_pulse/features/profile/avatar_widgets.dart';

import 'fakes.dart';
import 'l10n_helpers.dart';

Uint8List _jpeg(int w, int h) {
  final i = img.Image(width: w, height: h);
  img.fill(i, color: img.ColorRgb8(200, 60, 60));
  return Uint8List.fromList(img.encodeJpg(i, quality: 90));
}

Uint8List _png() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 8)));

class _FakeAvatars implements AvatarRepository {
  final calls = <String>[];
  Uint8List? bytes;

  @override
  Future<Uint8List?> photoOf(String userId) async {
    calls.add('photoOf:$userId');
    return bytes;
  }

  @override
  Future<Uint8List?> photoAt(String path) async {
    calls.add('photoAt:$path');
    return bytes;
  }

  @override
  Future<String> save(Uint8List jpeg) async {
    calls.add('save:${jpeg.length}');
    return 'u/new.jpg';
  }

  @override
  Future<void> remove() async => calls.add('remove');

  @override
  void clear() => calls.add('clear');
}

void main() {
  group('checkAvatarBytes', () {
    test('accepts JPEG and WebP by content', () {
      expect(checkAvatarBytes(_jpeg(10, 10)), isNull);
      final webp = Uint8List.fromList([
        ...'RIFF'.codeUnits,
        0,
        0,
        0,
        0,
        ...'WEBP'.codeUnits,
        0,
      ]);
      expect(checkAvatarBytes(webp), isNull);
    });
    test('rejects PNG, empty and oversize regardless of name', () {
      expect(checkAvatarBytes(_png())!.code, AppErrorCode.avatarType);
      expect(checkAvatarBytes(Uint8List(0))!.code, AppErrorCode.fileEmpty);
      final big = Uint8List(avatarMaxInputBytes + 1)..[0] = 0xFF;
      expect(checkAvatarBytes(big)!.code, AppErrorCode.avatarInputTooLarge);
    });
  });

  group('image pipeline', () {
    test('finishAvatar: square 256, JPEG, within 512 KB, centre-cropped', () {
      final out = finishAvatar(_jpeg(600, 400));
      expect(out.length, lessThanOrEqualTo(avatarMaxBytes));
      expect(out[0], 0xFF);
      expect(out[1], 0xD8);
      final d = img.decodeJpg(out)!;
      expect((d.width, d.height), (avatarSize, avatarSize));
    });
    test('prepareForCrop shrinks big pictures to <= 1280 px', () {
      final d = img.decodeJpg(prepareForCrop(_jpeg(2000, 1000)))!;
      expect((d.width, d.height), (1280, 640));
    });
    test('garbage is a decode error, not a crash', () {
      expect(
        () => finishAvatar(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<AppError>().having(
            (e) => e.code,
            'code',
            AppErrorCode.avatarDecode,
          ),
        ),
      );
    });
  });

  group('AvatarCircle', () {
    testWidgets('initials and no request when nothing may be shown', (t) async {
      final repo = _FakeAvatars();
      await t.pumpWidget(
        wrapWithL10n(
          AvatarCircle(repository: repo, userId: 'x', name: 'Sam Lee'),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('SL'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('own path loads the photo; lookup asks by user id', (t) async {
      final repo = _FakeAvatars()..bytes = _jpeg(16, 16);
      await t.pumpWidget(
        wrapWithL10n(
          Column(
            children: [
              AvatarCircle(
                repository: repo,
                userId: '',
                name: 'Own',
                path: 'u/a.jpg',
              ),
              AvatarCircle(
                repository: repo,
                userId: 'student-1',
                name: 'Stu',
                lookup: true,
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(repo.calls, containsAll(['photoAt:u/a.jpg', 'photoOf:student-1']));
      final avatars = t.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatars.every((a) => a.foregroundImage is MemoryImage), isTrue);
    });

    testWidgets('a refused photo stays initials', (t) async {
      final repo = _FakeAvatars(); // bytes == null: the server said no
      await t.pumpWidget(
        wrapWithL10n(
          AvatarCircle(
            repository: repo,
            userId: 's',
            name: 'Mei',
            lookup: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('M'), findsOneWidget);
      expect(
        t.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
        isNull,
      );
    });

    testWidgets('replacing the path reloads', (t) async {
      final repo = _FakeAvatars()..bytes = _jpeg(8, 8);
      Widget build(String p) => wrapWithL10n(
        AvatarCircle(repository: repo, userId: '', name: 'A', path: p),
      );
      await t.pumpWidget(build('u/1.jpg'));
      await t.pumpAndSettle();
      await t.pumpWidget(build('u/2.jpg'));
      await t.pumpAndSettle();
      expect(repo.calls, ['photoAt:u/1.jpg', 'photoAt:u/2.jpg']);
    });
  });

  group('AvatarPhotoSection', () {
    Future<(AuthController, _FakeAvatars)> open(
      WidgetTester t, {
      String? avatarPath,
      Future<Uint8List?> Function()? pick,
    }) async {
      final repo = _FakeAvatars();
      final auth = AuthController(
        FakeAuthRepository(
          hasSession: true,
          profile: Profile(
            role: AppRole.student,
            fullName: 'Sam Lee',
            avatarPath: avatarPath,
          ),
        ),
      );
      addTearDown(auth.dispose);
      await auth.start();
      await t.pumpWidget(
        wrapWithL10n(
          SingleChildScrollView(
            child: AvatarPhotoSection(
              controller: auth,
              avatars: repo,
              pick: pick,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      return (auth, repo);
    }

    testWidgets('a PNG is refused with a message; nothing is uploaded', (
      t,
    ) async {
      final (_, repo) = await open(t, pick: () async => _png());
      expect(find.text('Add photo'), findsOneWidget);
      expect(find.byKey(const Key('avatar-remove')), findsNothing);
      await t.tap(find.byKey(const Key('avatar-change')));
      await t.pumpAndSettle();
      expect(find.text('Choose a JPEG or WebP picture.'), findsOneWidget);
      expect(find.byKey(const Key('avatar-crop')), findsNothing);
      expect(repo.calls.where((c) => c.startsWith('save')), isEmpty);
    });

    testWidgets('remove clears the server pointer and the local profile', (
      t,
    ) async {
      final (auth, repo) = await open(t, avatarPath: 'u/old.jpg');
      expect(find.text('Change photo'), findsOneWidget);
      await t.tap(find.byKey(const Key('avatar-remove')));
      await t.pumpAndSettle();
      expect(repo.calls, contains('remove'));
      expect(auth.profile!.avatarPath, isNull);
      expect(find.text('Add photo'), findsOneWidget);
    });
  });

  test('applyAvatarPath updates the profile and notifies listeners', () async {
    final auth = AuthController(
      FakeAuthRepository(
        hasSession: true,
        profile: const Profile(role: AppRole.teacher, fullName: 'T'),
      ),
    );
    addTearDown(auth.dispose);
    await auth.start();
    var n = 0;
    auth.addListener(() => n++);
    auth.applyAvatarPath('u/x.jpg');
    expect(auth.profile!.avatarPath, 'u/x.jpg');
    expect(auth.profile!.fullName, 'T');
    expect(n, 1);
  });

  test('Profile.fromRow reads avatar_path and tolerates its absence', () {
    final p = Profile.fromRow({
      'role': 'student',
      'full_name': 'A',
      'avatar_path': 'u/p.jpg',
    });
    expect(p!.avatarPath, 'u/p.jpg');
    expect(
      Profile.fromRow({'role': 'teacher', 'full_name': 'B'})!.avatarPath,
      isNull,
    );
  });
}
