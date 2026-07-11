import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';

void main() {
  testWidgets('Learn Pulse app loads successfully', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Let’s keep learning!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Navigation opens courses page', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();

    expect(find.text('My courses'), findsOneWidget);
    expect(find.text('Track lessons and learning progress'), findsOneWidget);
  });

  testWidgets('Navigation opens tasks page', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Stay focused on what matters today'), findsOneWidget);
    expect(find.text('3 tasks remaining'), findsOneWidget);
  });

  testWidgets('Navigation opens profile page', (tester) async {
    await tester.pumpWidget(const LearnPulseApp());

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Learn Pulse User'), findsOneWidget);
    expect(find.text('About Learn Pulse'), findsOneWidget);
  });
}
