import 'package:flutter/foundation.dart';

import '../dashboard/summary_bus.dart';

import '../../core/app_error.dart';
import '../../l10n/app_localizations.dart';
import 'course.dart';
import 'course_repository.dart';

enum LoadState { loading, ready, error }

enum CoursesNotice { joined }

/// The signed-in user's course list plus the create / join / edit actions.
/// Every action is serialised ([busy]) so a double tap cannot send two requests.
class CoursesController extends ChangeNotifier {
  CoursesController(this._repo, {this.summaries});

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;

  final CourseRepository _repo;
  bool _disposed = false;

  LoadState state = LoadState.loading;
  List<Course> courses = const [];
  AppError? loadError;
  AppError? actionError;
  CoursesNotice? noticeKind;
  String? _noticeTitle;
  bool busy = false;

  /// English text of the current notice (logs and tests); UI uses [noticeText].
  String? get notice =>
      noticeKind == null ? null : 'Joined ${_noticeTitle ?? 'the course'}.';

  String? noticeText(AppLocalizations l) => noticeKind == null
      ? null
      : l.noticeJoinedCourse(_noticeTitle ?? l.noticeTheCourse);

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      courses = await _repo.listCourses();
      loadError = null;
      state = LoadState.ready;
    } on Object catch (e) {
      loadError = AppError.from(e);
      // Keep stale data visible on a failed refresh; only block the screen when there is none.
      state = courses.isEmpty || showSpinner
          ? LoadState.error
          : LoadState.ready;
    }
    notifyListeners();
  }

  /// Returns the new course (with its join code) or null on failure ([actionError] is set).
  Future<NewCourse?> create(String title, String description) async {
    NewCourse? created;
    await _act(() async {
      created = await _repo.createCourse(
        title: title.trim(),
        description: description.trim(),
      );
      summaries?.invalidate();
      await load(showSpinner: false);
    });
    return created;
  }

  Future<JoinResult?> join(String code) async {
    JoinResult? result;
    await _act(() async {
      result = await _repo.joinByCode(code.trim().toUpperCase());
      if (result!.outcome == JoinOutcome.joined) {
        summaries?.invalidate();
        noticeKind = CoursesNotice.joined;
        _noticeTitle = result!.title;
        await load(showSpinner: false);
      }
    });
    return result;
  }

  Future<bool> update(
    String courseId, {
    String? title,
    String? description,
    CourseStatus? status,
  }) async {
    var ok = false;
    await _act(() async {
      await _repo.updateCourse(
        courseId,
        title: title?.trim(),
        description: description?.trim(),
        status: status,
      );
      summaries?.invalidate();
      await load(showSpinner: false);
      ok = true;
    });
    return ok;
  }

  Future<void> _act(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    actionError = null;
    noticeKind = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (e) {
      actionError = AppError.from(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    actionError = null;
    noticeKind = null;
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

/// Teacher-only detail: the join code and the roster of one course.
class CourseDetailController extends ChangeNotifier {
  CourseDetailController(this._repo, this.courseId, {this.summaries});

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;

  final CourseRepository _repo;
  final String courseId;
  bool _disposed = false;

  LoadState state = LoadState.loading;
  String? joinCode;
  List<RosterEntry> roster = const [];
  AppError? error;
  AppError? actionError;
  bool busy = false;

  Future<void> load() async {
    state = LoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.joinCode(courseId),
        _repo.roster(courseId),
      ]);
      joinCode = results[0] as String;
      roster = results[1] as List<RosterEntry>;
      error = null;
      state = LoadState.ready;
    } on Object catch (e) {
      error = AppError.from(e);
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> remove(String studentId) async {
    if (busy) return;
    busy = true;
    actionError = null;
    notifyListeners();
    try {
      await _repo.removeMember(courseId, studentId);
      summaries?.invalidate();
      roster = await _repo.roster(courseId);
    } on Object catch (e) {
      actionError = AppError.from(e);
    } finally {
      busy = false;
      notifyListeners();
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
