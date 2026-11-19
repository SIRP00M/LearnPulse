import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_error.dart';
import '../../core/avatar_image.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'avatar_repository.dart';
import 'profile_pages.dart' show initialsOf;

/// Round avatar: the photo when one exists and may be shown, otherwise initials. Decorative (the name is always
/// shown beside it). Pass [path] for the signed-in user's own photo; set [lookup] only where the viewer may be
/// authorised (a teacher viewing a student), so nobody issues requests the server will refuse.
class AvatarCircle extends StatefulWidget {
  const AvatarCircle({
    super.key,
    required this.repository,
    required this.userId,
    required this.name,
    this.path,
    this.lookup = false,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final AvatarRepository repository;
  final String userId;
  final String name;
  final String? path;
  final bool lookup;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends State<AvatarCircle> {
  Uint8List? _bytes;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AvatarCircle old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId ||
        old.path != widget.path ||
        old.lookup != widget.lookup) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_gen;
    final w = widget;
    if (w.path == null && !w.lookup) {
      if (_bytes != null) setState(() => _bytes = null);
      return;
    }
    final b = w.path != null
        ? await w.repository.photoAt(w.path!)
        : await w.repository.photoOf(w.userId);
    if (mounted && gen == _gen) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.foregroundColor ?? scheme.onSecondaryContainer;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? scheme.secondaryContainer,
        foregroundImage: _bytes == null ? null : MemoryImage(_bytes!),
        onForegroundImageError: _bytes == null ? null : (_, _) {},
        child: Text(
          initialsOf(widget.name),
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: widget.radius * .8,
          ),
        ),
      ),
    );
  }
}

/// Square crop (circle overlay): drag and pinch; returns the cropped bytes, or null when cancelled.
class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.image});
  final Uint8List image;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final _controller = CropController();
  bool _busy = false;

  void _done(CropResult r) {
    if (!mounted) return;
    switch (r) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorAvatarDecode),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.profilePhotoCropTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l.profilePhotoCropHint),
            ),
            Expanded(
              child: Crop(
                key: const Key('avatar-crop'),
                image: widget.image,
                controller: _controller,
                aspectRatio: 1,
                withCircleUi: true,
                interactive: true,
                fixCropRect: true,
                baseColor: scheme.surface,
                maskColor: scheme.scrim.withValues(alpha: .55),
                onCropped: _done,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l.commonCancel),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('avatar-crop-save'),
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() => _busy = true);
                              _controller.crop();
                            },
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.profilePhotoSave),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Account-page section: large photo, add/change/remove. All server rules are enforced again by the database.
class AvatarPhotoSection extends StatefulWidget {
  const AvatarPhotoSection({
    super.key,
    required this.controller,
    required this.avatars,
    this.pick,
  });

  final AuthController controller;
  final AvatarRepository avatars;

  /// Test seam: returns the picked file's bytes (or null). Defaults to the system gallery.
  final Future<Uint8List?> Function()? pick;

  @override
  State<AvatarPhotoSection> createState() => _AvatarPhotoSectionState();
}

class _AvatarPhotoSectionState extends State<AvatarPhotoSection> {
  bool _busy = false;
  AppError? _error;

  Future<Uint8List?> _pickBytes() async {
    if (widget.pick != null) return widget.pick!();
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    return f?.readAsBytes();
  }

  Future<void> _change() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _error = null);
    try {
      final raw = await _pickBytes();
      if (raw == null || !mounted) return;
      final bad = checkAvatarBytes(raw);
      if (bad != null) throw bad;
      setState(() => _busy = true);
      final prepared = await compute(prepareForCrop, raw);
      if (!mounted) return;
      final cropped = await nav.push<Uint8List>(
        MaterialPageRoute(builder: (_) => AvatarCropPage(image: prepared)),
      );
      if (cropped == null || !mounted) return;
      final jpeg = await compute(finishAvatar, cropped);
      final path = await widget.avatars.save(jpeg);
      widget.controller.applyAvatarPath(path);
      messenger.showSnackBar(SnackBar(content: Text(l.profilePhotoSaved)));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.avatars.remove();
      widget.controller.applyAvatarPath(null);
      messenger.showSnackBar(SnackBar(content: Text(l.profilePhotoRemoved)));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.profile;
        final has = p?.avatarPath != null;
        return Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: l.profilePhotoSemantics(p?.fullName ?? ''),
                image: true,
                child: AvatarCircle(
                  key: const Key('account-avatar'),
                  repository: widget.avatars,
                  userId: '',
                  name: p?.fullName ?? '',
                  path: p?.avatarPath,
                  radius: 44,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profilePhotoHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('avatar-change'),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            has ? l.profilePhotoChange : l.profilePhotoAdd,
                          ),
                          onPressed: _busy ? null : _change,
                        ),
                        if (has)
                          TextButton.icon(
                            key: const Key('avatar-remove'),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l.profilePhotoRemove),
                            onPressed: _busy ? null : _remove,
                          ),
                      ],
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: Space.sm),
                        child: LinearProgressIndicator(),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: Text(
                          _error!.text(context),
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
