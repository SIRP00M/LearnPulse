import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';

void main() {
  testWidgets('role selection loads', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    expect(find.text('Learn Pulse'), findsOneWidget);
    expect(find.text('Continue as Teacher'), findsOneWidget);
    expect(find.text('Continue as Student'), findsOneWidget);
  });

  testWidgets('teacher flow opens dashboard', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    await tester.tap(find.text('Continue as Teacher'));
    await tester.pumpAndSettle();

    expect(find.text('Teacher Dashboard'), findsOneWidget);
    expect(find.text('Courses'), findsWidgets);
    expect(find.text('Students'), findsWidgets);
  });

  testWidgets('student flow opens home', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    await tester.tap(find.text('Continue as Student'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Alex'), findsOneWidget);
    expect(find.text('Overall progress'), findsOneWidget);
  });
}
