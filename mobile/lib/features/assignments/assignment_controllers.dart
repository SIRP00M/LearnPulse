import 'package:flutter/foundation.dart';

import '../dashboard/summary_bus.dart';

import '../../core/app_error.dart';
import '../../core/ids.dart';
import '../../l10n/app_localizations.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'assignment.dart';
import 'assignment_repository.dart';

/// Assignments of one course. Students also get their own submissions (status badges).
class AssignmentsController extends ChangeNotifier {
  AssignmentsController(
    this._repo,
    this.courseId, {
    this.student = false,
    this.summaries,
  });

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;

  final AssignmentRepository _repo;
  final String courseId;
  final bool student;
  bool _disposed = false;

  LoadState state = LoadState.loading;
  List<Assignment> assignments = const [];
  Map<String, Submission> mine = const {};
  AppError? loadError;
  AppError? actionError;
  bool busy = false;

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      assignments = await _repo.listAssignments(courseId);
      if (student) {
        final subs = await _repo.listMySubmissions();
        mine = {for (final s in subs) s.assignmentId: s};
      }
      loadError = null;
      state = LoadState.ready;
    } on Object catch (e) {
      loadError = AppError.from(e);
      state = assignments.isEmpty || showSpinner
          ? LoadState.error
          : LoadState.ready;
    }
    notifyListeners();
  }

  Future<bool> create({
    required String title,
    required String instructions,
    required int maxScore,
    DateTime? dueAt,
  }) => _act(
    () => _repo.createAssignment(
      courseId: courseId,
      title: title.trim(),
      instructions: instructions.trim(),
      maxScore: maxScore,
      dueAt: dueAt,
    ),
  );

  Future<bool> update(
    Assignment a, {
    required String title,
    required String instructions,
    required int maxScore,
    DateTime? dueAt,
    bool clearDue = false,
  }) => _act(
    () => _repo.updateAssignment(
      a.id,
      a.version,
      title: title.trim(),
      instructions: instructions.trim(),
      maxScore: maxScore,
      dueAt: dueAt,
      clearDue: clearDue,
    ),
  );

  Future<bool> publish(Assignment a) => _act(() async {
    await _repo.publishAssignment(a.id, a.version);
    summaries?.invalidate();
  });

  Future<bool> _act(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    actionError = null;
    notifyListeners();
    var ok = false;
    try {
      await action();
      await load(showSpinner: false);
      ok = true;
    } on Object catch (e) {
      actionError = AppError.from(e);
      if (actionError!.kind == AppErrorKind.conflict) {
        await load(showSpinner: false); // pick up the newer version
      }
    } finally {
      busy = false;
      notifyListeners();
    }
    return ok;
  }

  void clearError() {
    actionError = null;
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

/// Teacher view of the submissions to one assignment.
class SubmissionsController extends ChangeNotifier {
  SubmissionsController(this._repo, this.assignmentId);

  final AssignmentRepository _repo;
  final String assignmentId;
  bool _disposed = false;

  LoadState state = LoadState.loading;
  List<Submission> submissions = const [];
  AppError? error;
  AppError? fileError;

  Future<void> load() async {
    state = LoadState.loading;
    notifyListeners();
    try {
      submissions = await _repo.listSubmissions(assignmentId);
      error = null;
      state = LoadState.ready;
    } on Object catch (e) {
      error = AppError.from(e);
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// A short-lived signed URL for an attachment (the server re-checks access every time).
  Future<String?> urlFor(UploadInfo upload) async {
    fileError = null;
    try {
      return await _repo.signedUrl(upload.path);
    } on Object catch (e) {
      fileError = AppError.from(e);
      notifyListeners();
      return null;
    }
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

enum SubmitPhase { idle, uploading, submitting }

enum SubmitNotice { saved }

/// The student's answer form. Retries are safe: the idempotency key, upload ticket and upload state
/// survive failures and are reused until the content changes or the server says the upload is unusable.
class SubmissionController extends ChangeNotifier {
  SubmissionController(
    this._repo,
    this._picker,
    this.assignment, {
    Submission? existing,
    String Function()? newId,
    this.summaries,
  }) : existing = existing,
       _newId = newId ?? newRequestId,
       answer = existing?.answer ?? '' {
    _requestId = _newId();
  }

  final AssignmentRepository _repo;
  final FilePickerService _picker;

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;
  final Assignment assignment;
  final String Function() _newId;
  bool _disposed = false;

  Submission? existing;
  String answer;
  PickedFile? picked;
  bool clearAttachment = false;
  SubmitPhase phase = SubmitPhase.idle;
  AppError? error;
  bool needsReload = false;
  SubmitNotice? noticeKind;

  /// English text of the current notice (logs and tests); UI uses [noticeText].
  String? get notice => noticeKind == null ? null : 'Submission saved.';

  String? noticeText(AppLocalizations l) =>
      noticeKind == null ? null : l.noticeSubmissionSaved;

  late String _requestId;
  UploadTicket? _ticket;
  bool _uploaded = false;
  String _signature = '';

  bool get busy => phase != SubmitPhase.idle;

  void setAnswer(String v) {
    answer = v;
  }

  Future<void> pickFile() async {
    if (busy) return;
    try {
      final f = await _picker.pick();
      if (f == null) return;
      if (f.size > maxUploadBytes) {
        error = const AppError(
          AppErrorKind.validation,
          'That file is larger than 10 MB.',
          AppErrorCode.fileLarger,
        );
      } else if (f.size == 0) {
        error = const AppError(
          AppErrorKind.validation,
          'That file is empty.',
          AppErrorCode.fileEmpty,
        );
      } else {
        picked = f;
        clearAttachment = false;
        error = null;
        _ticket = null;
        _uploaded = false;
      }
    } on Object catch (e) {
      error = AppError.from(e);
    }
    notifyListeners();
  }

  void removePicked() {
    picked = null;
    _ticket = null;
    _uploaded = false;
    notifyListeners();
  }

  void setClearAttachment(bool v) {
    clearAttachment = v;
    if (v) picked = null;
    notifyListeners();
  }

  String _sig() =>
      '${assignment.id}|$answer|${picked?.name}|${picked?.size}|$clearAttachment|${existing?.version}';

  Future<void> submit() async {
    if (busy) return;
    final hasFile =
        picked != null || (existing?.upload != null && !clearAttachment);
    if (answer.trim().isEmpty && !hasFile) {
      error = const AppError(
        AppErrorKind.validation,
        'Write an answer or attach a file.',
        AppErrorCode.writeOrAttach,
      );
      notifyListeners();
      return;
    }
    final sig = _sig();
    if (sig != _signature) {
      _requestId =
          _newId(); // new content = new idempotency key; an unchanged retry keeps the old one
      _signature = sig;
    }
    error = null;
    noticeKind = null;
    needsReload = false;
    try {
      final file = picked;
      if (file != null) {
        phase = SubmitPhase.uploading;
        notifyListeners();
        _ticket ??= await _repo.prepareUpload(assignment.id, file);
        if (!_uploaded) {
          await _repo.uploadBytes(_ticket!, file);
          _uploaded = true;
        }
      }
      phase = SubmitPhase.submitting;
      notifyListeners();
      final saved = await _repo.submit(
        assignmentId: assignment.id,
        requestId: _requestId,
        answer: answer,
        uploadId: picked != null ? _ticket?.uploadId : null,
        expectedVersion: existing?.version,
        clearAttachment: clearAttachment,
      );
      summaries?.invalidate();
      picked = null;
      clearAttachment = false;
      _ticket = null;
      _uploaded = false;
      _requestId = _newId();
      _signature = '';
      existing = saved;
      noticeKind = SubmitNotice.saved;
      await _refreshExisting();
    } on Object catch (e) {
      final err = AppError.from(e);
      error = err;
      if (err.kind == AppErrorKind.conflict) {
        final m = err.message;
        if (m.contains('not uploaded') ||
            m.contains('does not match') ||
            m.contains('expired')) {
          _ticket = null;
          _uploaded = false; // the file must be sent again
          error = const AppError(
            AppErrorKind.conflict,
            "The file didn't finish uploading. Tap Submit to try again.",
            AppErrorCode.uploadIncomplete,
          );
        } else if (m.contains('changed elsewhere')) {
          needsReload = true;
          error = const AppError(
            AppErrorKind.conflict,
            'Your submission was changed on another device. Reload to continue; your text is kept.',
            AppErrorCode.submissionChanged,
          );
        }
      }
    } finally {
      phase = SubmitPhase.idle;
      notifyListeners();
    }
  }

  /// Fetches the latest saved submission (new version) without discarding what the student typed.
  Future<void> reload() async {
    if (busy) return;
    await _refreshExisting();
    needsReload = false;
    error = null;
    notifyListeners();
  }

  Future<void> _refreshExisting() async {
    try {
      final all = await _repo.listMySubmissions();
      final match = all.where((s) => s.assignmentId == assignment.id);
      existing = match.isEmpty ? null : match.first;
    } on Object catch (_) {
      // Keep the response we already have; the next screen load refreshes it.
    }
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
