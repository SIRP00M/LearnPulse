import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart' show BuildContext;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

enum AppErrorKind {
  network,
  timeout,
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  weakPassword,
  signupDisabled,
  forbidden,
  notFound,
  validation,
  conflict,
  profileMissing,
  unknown,
}

/// Stable id of a standard message; resolved with [AppError.localizedMessage] at render time so a
/// visible error re-translates when the language changes. Errors without a code (feature-specific
/// or server-supplied text) show their English [AppError.message] until PART 2 gives them a code.
enum AppErrorCode {
  network,
  timeout,
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  rateLimitedLong,
  weakPassword,
  signupDisabled,
  fileForbidden,
  fileTooLarge,
  fileType,
  forbidden,
  courseNotFound,
  validation,
  sessionExpired,
  unknown,
  notSignedIn,
  nameNotSaved,
  profileNotReady,
  scoreWhole,
  scoreRange,
  feedbackLong,
  returnReason,
  fileLarger,
  fileEmpty,
  writeOrAttach,
  uploadIncomplete,
  submissionChanged,
  gradeConflict,
  fileNoAccess,
  fileTypeList,
  noteTooLong,
  recordChanged,
  sessionNotFound,
  activityNotFound,
  assignmentUnavailable,
  courseUnavailable,
  avatarType,
  avatarInputTooLarge,
  avatarDecode,
}

/// A user-presentable failure. Never contains tokens or server internals.
class AppError implements Exception {
  const AppError(this.kind, this.message, [this.code, this.args = const []]);

  final AppErrorKind kind;

  /// English text for logs and tests; UI should call [localizedMessage].
  final String message;
  final AppErrorCode? code;

  /// Values interpolated into the localized text (e.g. the maximum score).
  final List<int> args;

  /// The message in the active language (falls back to [message] when there is no [code]).
  String localizedMessage(AppLocalizations l) => switch (code) {
    null => message,
    AppErrorCode.network => l.errorNetwork,
    AppErrorCode.timeout => l.errorTimeout,
    AppErrorCode.invalidCredentials => l.errorInvalidCredentials,
    AppErrorCode.emailNotConfirmed => l.errorEmailNotConfirmed,
    AppErrorCode.rateLimited => l.errorRateLimited,
    AppErrorCode.rateLimitedLong => l.errorRateLimitedLong,
    AppErrorCode.weakPassword => l.errorWeakPassword,
    AppErrorCode.signupDisabled => l.errorSignupDisabled,
    AppErrorCode.fileForbidden => l.errorFileForbidden,
    AppErrorCode.fileTooLarge => l.errorFileTooLarge,
    AppErrorCode.fileType => l.errorFileType,
    AppErrorCode.forbidden => l.errorForbidden,
    AppErrorCode.courseNotFound => l.errorCourseNotFound,
    AppErrorCode.validation => l.errorValidation,
    AppErrorCode.sessionExpired => l.errorSessionExpired,
    AppErrorCode.unknown => l.errorUnknown,
    AppErrorCode.notSignedIn => l.errorNotSignedIn,
    AppErrorCode.nameNotSaved => l.errorNameNotSaved,
    AppErrorCode.profileNotReady => l.errorProfileNotReady,
    AppErrorCode.scoreWhole => l.errorScoreWhole,
    AppErrorCode.scoreRange => l.errorScoreRange(args.isEmpty ? 0 : args.first),
    AppErrorCode.feedbackLong => l.errorFeedbackLong,
    AppErrorCode.returnReason => l.errorReturnReason,
    AppErrorCode.fileLarger => l.errorFileLarger,
    AppErrorCode.fileEmpty => l.errorFileEmpty,
    AppErrorCode.writeOrAttach => l.errorWriteOrAttach,
    AppErrorCode.uploadIncomplete => l.errorUploadIncomplete,
    AppErrorCode.submissionChanged => l.errorSubmissionChanged,
    AppErrorCode.gradeConflict => l.errorGradeConflict,
    AppErrorCode.fileNoAccess => l.errorFileNoAccess,
    AppErrorCode.fileTypeList => l.errorFileTypeList,
    AppErrorCode.noteTooLong => l.errorNoteTooLong,
    AppErrorCode.recordChanged => l.errorRecordChanged,
    AppErrorCode.sessionNotFound => l.errorSessionNotFound,
    AppErrorCode.activityNotFound => l.errorActivityNotFound,
    AppErrorCode.assignmentUnavailable => l.errorAssignmentUnavailable,
    AppErrorCode.courseUnavailable => l.errorCourseUnavailable,
    AppErrorCode.avatarType => l.errorAvatarType,
    AppErrorCode.avatarInputTooLarge => l.errorAvatarInputTooLarge,
    AppErrorCode.avatarDecode => l.errorAvatarDecode,
  };

  /// Convenience for widgets: `error.text(context)`.
  String text(BuildContext context) =>
      localizedMessage(AppLocalizations.of(context));

  @override
  String toString() => 'AppError($kind)';

  static AppError from(Object error) {
    if (error is AppError) return error;
    if (error is TimeoutException) {
      return const AppError(
        AppErrorKind.timeout,
        'The server took too long to answer. Try again in a moment.',
        AppErrorCode.timeout,
      );
    }
    if (error is SocketException) {
      return const AppError(
        AppErrorKind.network,
        'No connection to the server. Check your network and try again.',
        AppErrorCode.network,
      );
    }
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return const AppError(
            AppErrorKind.invalidCredentials,
            'Email or password is incorrect.',
            AppErrorCode.invalidCredentials,
          );
        case 'email_not_confirmed':
          return const AppError(
            AppErrorKind.emailNotConfirmed,
            'Please confirm your email address first.',
            AppErrorCode.emailNotConfirmed,
          );
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          return const AppError(
            AppErrorKind.rateLimited,
            'Too many attempts. Please wait a moment and try again.',
            AppErrorCode.rateLimited,
          );
        case 'weak_password':
          return const AppError(
            AppErrorKind.weakPassword,
            'Choose a stronger password (10+ characters with upper, lower case and a digit).',
            AppErrorCode.weakPassword,
          );
        case 'signup_disabled':
          return const AppError(
            AppErrorKind.signupDisabled,
            'Registration is currently closed.',
            AppErrorCode.signupDisabled,
          );
      }
      if (error.statusCode == '429') {
        return const AppError(
          AppErrorKind.rateLimited,
          'Too many attempts. Please wait a moment and try again.',
          AppErrorCode.rateLimited,
        );
      }
    }
    if (error is StorageException) {
      final code = error.statusCode;
      if (code == '401' ||
          code == '403' ||
          error.message.contains('row-level security')) {
        return const AppError(
          AppErrorKind.forbidden,
          'You are not allowed to upload or open that file.',
          AppErrorCode.fileForbidden,
        );
      }
      if (code == '413') {
        return const AppError(
          AppErrorKind.validation,
          'That file is too large (10 MB maximum).',
          AppErrorCode.fileTooLarge,
        );
      }
      if (code == '415') {
        return const AppError(
          AppErrorKind.validation,
          'That file type is not allowed.',
          AppErrorCode.fileType,
        );
      }
    }
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PT429':
          return const AppError(
            AppErrorKind.rateLimited,
            'Too many attempts. Please wait a few minutes and try again.',
            AppErrorCode.rateLimitedLong,
          );
        case 'PT403':
        case '42501':
          return const AppError(
            AppErrorKind.forbidden,
            'You do not have permission to do that.',
            AppErrorCode.forbidden,
          );
        case 'PT404':
          return const AppError(
            AppErrorKind.notFound,
            'That course was not found, or you no longer have access to it.',
            AppErrorCode.courseNotFound,
          );
        case 'PT400':
          return AppError(
            AppErrorKind.validation,
            error.message.isEmpty
                ? 'Please check the details and try again.'
                : error.message,
            error.message.isEmpty ? AppErrorCode.validation : null,
          );
        case 'PT409':
          return AppError(AppErrorKind.conflict, error.message);
        case 'PT401':
          return const AppError(
            AppErrorKind.invalidCredentials,
            'Your session has expired. Please sign in again.',
            AppErrorCode.sessionExpired,
          );
      }
    }
    final text = error.toString();
    if (text.contains('ClientException') || text.contains('SocketException')) {
      return const AppError(
        AppErrorKind.network,
        'No connection to the server. Check your network and try again.',
        AppErrorCode.network,
      );
    }
    return const AppError(
      AppErrorKind.unknown,
      'Something went wrong. Please try again.',
      AppErrorCode.unknown,
    );
  }
}
