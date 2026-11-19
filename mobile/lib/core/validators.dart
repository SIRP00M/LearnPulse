import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Client-side form checks. The server remains the authority (Auth password policy, RLS).
///
/// Validators return a [ValidationIssue] (not text) so the visible message is resolved with
/// [AppLocalizations] at render time and re-translates when the language changes. Wire a field with
/// `validator: fieldValidator(validateEmail), errorBuilder: validationErrorBuilder`.
enum ValidationIssue {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordShort,
  passwordMix,
  nameRequired,
  nameLong,
  titleRequired,
  titleLong,
  maxScoreRange,
  joinCodeRequired,
  joinCodeFormat;

  String text(AppLocalizations l) => switch (this) {
    emailRequired => l.validationEmailRequired,
    emailInvalid => l.validationEmailInvalid,
    passwordRequired => l.validationPasswordRequired,
    passwordShort => l.validationPasswordShort,
    passwordMix => l.validationPasswordMix,
    nameRequired => l.validationNameRequired,
    nameLong => l.validationNameLong,
    titleRequired => l.validationTitleRequired,
    titleLong => l.validationTitleLong,
    maxScoreRange => l.validationMaxScoreRange,
    joinCodeRequired => l.validationJoinCodeRequired,
    joinCodeFormat => l.validationJoinCodeFormat,
  };
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

ValidationIssue? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return ValidationIssue.emailRequired;
  if (!_email.hasMatch(v)) return ValidationIssue.emailInvalid;
  return null;
}

/// Mirrors the Auth policy: at least 10 characters with upper case, lower case and a digit.
ValidationIssue? validateNewPassword(String? value) {
  final v = value ?? '';
  if (v.length < 10) return ValidationIssue.passwordShort;
  if (!RegExp('[a-z]').hasMatch(v) ||
      !RegExp('[A-Z]').hasMatch(v) ||
      !RegExp('[0-9]').hasMatch(v)) {
    return ValidationIssue.passwordMix;
  }
  return null;
}

ValidationIssue? validatePasswordPresent(String? value) =>
    (value ?? '').isEmpty ? ValidationIssue.passwordRequired : null;

ValidationIssue? validateFullName(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return ValidationIssue.nameRequired;
  if (v.length > 120) return ValidationIssue.nameLong;
  return null;
}

/// Title shared by courses, lessons and assignments (1..120 characters).
ValidationIssue? validateTitle(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return ValidationIssue.titleRequired;
  if (t.length > 120) return ValidationIssue.titleLong;
  return null;
}

/// Adapts an issue-returning validator to a [FormFieldValidator] (the field stores the issue name).
FormFieldValidator<String> fieldValidator(
  ValidationIssue? Function(String?) validate,
) =>
    (value) => validate(value)?.name;

/// `errorBuilder` for fields using [fieldValidator]: looks the message up in the active language
/// on every build, so a visible error follows a language switch.
Widget validationErrorBuilder(BuildContext context, String name) {
  final issue = ValidationIssue.values.asNameMap()[name];
  final text = issue == null ? name : issue.text(AppLocalizations.of(context));
  return Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}
