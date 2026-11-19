import 'dart:io';

// The test runner is inside the Flutter SDK; avoid a developer-specific SDK path.
String sdkFonts() {
  final configured = Platform.environment['FLUTTER_ROOT'];
  if (configured != null) {
    final fonts = Directory('$configured/bin/cache/artifacts/material_fonts');
    if (fonts.existsSync()) return fonts.path;
  }
  var directory = File(Platform.resolvedExecutable).parent;
  while (true) {
    final fonts = Directory(
      '${directory.path}/bin/cache/artifacts/material_fonts',
    );
    if (fonts.existsSync()) return fonts.path;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Flutter SDK fonts missing. Set FLUTTER_ROOT to your SDK.');
}
