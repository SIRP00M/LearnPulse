import 'package:flutter/foundation.dart';

import '../dashboard/summary_bus.dart';

import '../../core/app_error.dart';
import '../../core/ids.dart';
import '../../l10n/app_localizations.dart';
import 'assignment.dart';
import 'assignment_repository.dart';

enum GradeNotice { saved, returned }

/// Teacher grading of one submission. Retries are safe: the idempotency key is reused while the payload
/// is unchanged, and a version conflict refreshes the submission but keeps what the teacher typed.
class GradingController extends ChangeNotifier {
  GradingController(
    this._repo,
    this.assignment,
    Submission submission, {
    String Function()? newId,
    this.summaries,
  }) : submission = submission,
       _newId = newId ?? newRequestId,
       scoreText = submission.score?.toString() ?? '',
       feedback = submission.feedback ?? '' {
    _requestId = _newId();
  }

  final AssignmentRepository _repo;

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;
  final Assignment assignment;
  final String Function() _newId;
  bool _disposed = false;

  Submission submission;
  String scoreText;
  String feedback;
  List<GradeEvent> history = const [];
  bool busy = false;
  bool needsReload = false;
  AppError? error;
  GradeNotice? noticeKind;

  /// English text of the current notice (logs and tests); UI uses [noticeText].
  String? get notice => switch (noticeKind) {
    null => null,
    GradeNotice.saved => 'Grade saved.',
    GradeNotice.returned => 'Returned to the student for revision.',
  };

  String? noticeText(AppLocalizations l) => switch (noticeKind) {
    null => null,
    GradeNotice.saved => l.noticeGradeSaved,
    GradeNotice.returned => l.noticeReturnedForRevision,
  };

  late String _requestId;
  String _signature = '';

  bool get canAct => submission.status != SubmissionStatus.returned;

  void setScore(String v) => scoreText = v;
  void setFeedback(String v) => feedback = v;

  /// Null when valid; otherwise a localizable problem for the score field.
  AppError? scoreProblem() {
    final n = int.tryParse(scoreText.trim());
    if (n == null) {
      return const AppError(
        AppErrorKind.validation,
        'Enter a whole number',
        AppErrorCode.scoreWhole,
      );
    }
    if (n < 0 || n > assignment.maxScore) {
      return AppError(
        AppErrorKind.validation,
        'Score must be between 0 and ${assignment.maxScore}',
        AppErrorCode.scoreRange,
        [assignment.maxScore],
      );
    }
    return null;
  }

  Future<void> loadHistory() async {
    try {
      history = await _repo.listEvents(submission.id);
    } on Object catch (_) {
      // History is informational; the grading actions do not depend on it.
    }
    notifyListeners();
  }

  Future<void> saveGrade() async {
    if (busy) return;
    final problem = scoreProblem();
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    if (feedback.trim().length > maxFeedbackLength) {
      error = const AppError(
        AppErrorKind.validation,
        'Feedback is too long (5000 characters maximum).',
        AppErrorCode.feedbackLong,
      );
      notifyListeners();
      return;
    }
    final score = int.parse(scoreText.trim());
    await _run(
      'grade|$score|${feedback.trim()}',
      () => _repo.gradeSubmission(
        submissionId: submission.id,
        requestId: _requestId,
        expectedVersion: submission.version,
        score: score,
        feedback: feedback.trim(),
      ),
      GradeNotice.saved,
    );
  }

  Future<void> returnForRevision() async {
    if (busy) return;
    if (feedback.trim().isEmpty) {
      error = const AppError(
        AppErrorKind.validation,
        'Explain what the student should revise.',
        AppErrorCode.returnReason,
      );
      notifyListeners();
      return;
    }
    if (feedback.trim().length > maxFeedbackLength) {
      error = const AppError(
        AppErrorKind.validation,
        'Feedback is too long (5000 characters maximum).',
        AppErrorCode.feedbackLong,
      );
      notifyListeners();
      return;
    }
    await _run(
      'return|${feedback.trim()}',
      () => _repo.returnSubmission(
        submissionId: submission.id,
        requestId: _requestId,
        expectedVersion: submission.version,
        feedback: feedback.trim(),
      ),
      GradeNotice.returned,
    );
  }

  Future<void> _run(
    String signature,
    Future<Submission> Function() call,
    GradeNotice done,
  ) async {
    final sig = '$signature|v${submission.version}';
    if (sig != _signature) {
      _requestId =
          _newId(); // new content or a new version = a new action; an unchanged retry reuses the key
      _signature = sig;
    }
    busy = true;
    error = null;
    noticeKind = null;
    needsReload = false;
    notifyListeners();
    try {
      final result = await call();
      summaries?.invalidate();
      submission = Submission(
        id: submission.id,
        assignmentId: submission.assignmentId,
        studentId: submission.studentId,
        studentName: submission.studentName,
        answer: submission.answer,
        version: result.version,
        submittedAt: submission.submittedAt,
        upload: submission.upload,
        status: result.status,
        score: result.score,
        feedback: result.feedback,
        gradedAt: result.gradedAt,
      );
      noticeKind = done;
      _signature = '';
      _requestId = _newId();
      await loadHistory();
    } on Object catch (e) {
      final err = AppError.from(e);
      error = err;
      if (err.kind == AppErrorKind.conflict) {
        needsReload = true;
        error = const AppError(
          AppErrorKind.conflict,
          'This submission changed (for example the student resubmitted). Reload to see the latest; your typed score and feedback are kept.',
          AppErrorCode.gradeConflict,
        );
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Fetches the latest submission and history without discarding the typed score and feedback.
  Future<void> reload() async {
    if (busy) return;
    try {
      final all = await _repo.listSubmissions(assignment.id);
      final match = all.where((s) => s.id == submission.id);
      if (match.isNotEmpty) submission = match.first;
      needsReload = false;
      error = null;
      await loadHistory();
    } on Object catch (e) {
      error = AppError.from(e);
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
