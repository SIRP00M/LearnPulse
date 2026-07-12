import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learn_pulse/pages/auth/login_page.dart';
import 'package:learn_pulse/pages/auth/register_page.dart';

void main() {
  Widget createLoginTestApp() {
    return const MaterialApp(home: LoginPage());
  }

  Widget createRegisterTestApp() {
    return const MaterialApp(home: RegisterPage());
  }

  testWidgets('login page loads successfully', (tester) async {
    await tester.pumpWidget(createLoginTestApp());

    expect(find.text('Welcome to Learn Pulse'), findsOneWidget);

    expect(find.text('Sign in to continue'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    expect(find.text('No account yet? Create one'), findsOneWidget);
  });

  testWidgets('login form accepts text and hides password', (tester) async {
    await tester.pumpWidget(createLoginTestApp());

    final emailField = find.widgetWithText(TextField, 'Email');

    final passwordField = find.widgetWithText(TextField, 'Password');

    await tester.enterText(emailField, 'teacher@example.com');

    await tester.enterText(passwordField, 'Test123456!');

    expect(find.text('teacher@example.com'), findsOneWidget);

    final passwordTextField = tester.widget<TextField>(passwordField);

    expect(passwordTextField.obscureText, isTrue);

    expect(passwordTextField.controller?.text, 'Test123456!');
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(createLoginTestApp());

    final passwordField = find.widgetWithText(TextField, 'Password');

    TextField passwordTextField = tester.widget<TextField>(passwordField);

    expect(passwordTextField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));

    await tester.pump();

    passwordTextField = tester.widget<TextField>(passwordField);

    expect(passwordTextField.obscureText, isFalse);

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('login page opens register page', (tester) async {
    await tester.pumpWidget(createLoginTestApp());

    await tester.tap(find.text('No account yet? Create one'));

    await tester.pumpAndSettle();

    expect(find.text('Join Learn Pulse'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);

    expect(find.text('Student'), findsOneWidget);

    expect(find.text('Teacher'), findsOneWidget);
  });

  testWidgets('register page loads successfully', (tester) async {
    await tester.pumpWidget(createRegisterTestApp());

    expect(find.text('Join Learn Pulse'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
  });

  testWidgets('student role is selected by default', (tester) async {
    await tester.pumpWidget(createRegisterTestApp());

    final segmentedButton = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );

    expect(segmentedButton.selected, contains('student'));
  });

  testWidgets('teacher role can be selected', (tester) async {
    await tester.pumpWidget(createRegisterTestApp());

    await tester.tap(find.text('Teacher'));
    await tester.pump();

    final segmentedButton = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );

    expect(segmentedButton.selected, contains('teacher'));
  });
}
