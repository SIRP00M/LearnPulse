import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'app_error.dart';

/// Avatar pipeline: pick -> [prepareForCrop] -> user crop -> [finishAvatar] -> upload. The server re-checks type and size.
const avatarSize = 256;
const avatarMaxBytes = 512 * 1024;
const avatarMaxInputBytes =
    10 * 1024 * 1024; // decode-safety cap on the picked file, not on the upload

AppError _err(AppErrorCode c, String m) =>
    AppError(AppErrorKind.validation, m, c);

/// Validates the picked file by its CONTENT (JPEG or WebP magic bytes), not by its name or declared type.
AppError? checkAvatarBytes(Uint8List b) {
  if (b.isEmpty) {
    return _err(AppErrorCode.fileEmpty, 'That file is empty.');
  }
  if (b.length > avatarMaxInputBytes) {
    return _err(
      AppErrorCode.avatarInputTooLarge,
      'That picture is too large (10 MB maximum).',
    );
  }
  final jpeg = b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
  final webp =
      b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';
  return jpeg || webp
      ? null
      : _err(AppErrorCode.avatarType, 'Choose a JPEG or WebP picture.');
}

/// Decodes, applies the EXIF orientation and shrinks (longest side <= 1280) so the crop screen stays smooth.
/// Top-level and pure so it can run in an isolate with `compute`.
Uint8List prepareForCrop(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    throw _err(AppErrorCode.avatarDecode, 'That picture could not be read.');
  }
  var image = img.bakeOrientation(decoded);
  final longest = math.max(image.width, image.height);
  if (longest > 1280) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1280 : null,
      height: image.height > image.width ? 1280 : null,
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

/// Square-crops (if needed), resizes to 256x256 and re-encodes as JPEG (strips all metadata), lowering quality
/// until the result fits 512 KB. Top-level and pure for `compute`.
Uint8List finishAvatar(Uint8List cropped) {
  final decoded = img.decodeImage(cropped);
  if (decoded == null) {
    throw _err(AppErrorCode.avatarDecode, 'That picture could not be read.');
  }
  final side = math.min(decoded.width, decoded.height);
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final small = img.copyResize(
    square,
    width: avatarSize,
    height: avatarSize,
    interpolation: img.Interpolation.average,
  );
  for (var q = 85; q >= 40; q -= 15) {
    final out = Uint8List.fromList(img.encodeJpg(small, quality: q));
    if (out.length <= avatarMaxBytes) return out;
  }
  throw _err(AppErrorCode.avatarDecode, 'The photo could not be prepared.');
}
