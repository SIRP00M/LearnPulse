import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/theme.dart';

import '../tool/studio_preview.dart' show createPreviewRoutes;

const _roots = {'student', 'teacher'};
const _routes = [
  'sign-in',
  'student',
  'teacher',
  'student-courses',
  'teacher-courses',
  'student-course',
  'teacher-class',
  'lesson',
  'lesson-editor',
  'assignment',
  'teacher-assignment',
  'grading',
  'attendance',
  'summary',
  'week',
  'account',
  'tasks',
  'tasks-teacher',
  'student-activities',
  'teacher-activity',
  'activity-form',
  'pending',
  'progress-teacher',
  'progress-student',
];

// Mid-word breaks cannot be judged here: the test font (Ahem) is far wider than the real one. They are
// checked on the emulator at 300% (see docs/CLAUDE_UI_STATES_ACCEPTANCE.md).
void main() {
  for (final c in [
    (w: 320.0, scale: 2.0),
    (w: 320.0, scale: 3.0),
    (w: 393.0, scale: 1.0),
    (w: 1024.0, scale: 1.0),
  ]) {
    testWidgets(
      'every page lays out without overflow at ${c.w.round()} dp ×${c.scale}',
      (tester) async {
        final routes = await createPreviewRoutes(onDispose: addTearDown);
        tester.view.physicalSize = Size(c.w, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final problems = <String>[];
        for (final r in _routes) {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: l10nDelegates,
              supportedLocales: l10nLocales,
              theme: buildTheme(Brightness.light, reduceMotion: true),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(c.scale)),
                child: child!,
              ),
              home: Builder(builder: routes['/$r']!),
            ),
          );
          if (_roots.contains(r)) {
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 300));
            }
          } else {
            await tester.pumpAndSettle();
          }
          final ex = tester.takeException();
          if (ex != null) problems.add('$r: overflow/exception');
        }
        expect(problems, isEmpty);
      },
    );
  }
}
