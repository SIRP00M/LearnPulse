import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../assignments/assignment.dart' show PickedFile, maxUploadBytes;
import '../courses/courses_controller.dart' show LoadState;
import 'lesson.dart';
import 'lesson_repository.dart';

/// Lessons and their attached files for one course (teacher: all; student: published only, via RLS).
class LessonsController extends ChangeNotifier {
  LessonsController(this._repo, this.courseId);

  final LessonRepository _repo;
  final String courseId;
  bool _disposed = false;

  LoadState state = LoadState.loading;
  List<Lesson> lessons = const [];
  Map<String, List<LessonResource>> resources = const {};
  AppError? loadError;
  AppError? actionError;
  bool busy = false;

  // Retry safety: while the same file is attached to the same lesson the ticket is reused, so a lost
  // response never creates a second pending resource.
  String? _ticketLesson;
  PickedFile? _ticketFile;
  ResourceTicket? _ticket;

  Lesson? lesson(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<LessonResource> filesOf(String lessonId) =>
      resources[lessonId] ?? const [];

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      lessons = await _repo.listLessons(courseId);
      final all = await _repo.listResources(courseId);
      final by = <String, List<LessonResource>>{};
      for (final r in all.where((r) => r.attached)) {
        (by[r.lessonId] ??= []).add(r);
      }
      resources = by;
      loadError = null;
      state = LoadState.ready;
    } on Object catch (e) {
      loadError = AppError.from(e);
      state = lessons.isEmpty || showSpinner
          ? LoadState.error
          : LoadState.ready;
    }
    notifyListeners();
  }

  Future<bool> create(String title, String body) =>
      _act(() => _repo.createLesson(courseId, title.trim(), body));

  Future<bool> update(Lesson l, String title, String body) => _act(
    () => _repo.updateLesson(l.id, l.version, title: title.trim(), body: body),
  );

  Future<bool> setPublished(Lesson l, bool publish) =>
      _act(() => _repo.setPublished(l.id, l.version, publish));

  Future<bool> delete(Lesson l) =>
      _act(() => _repo.deleteLesson(l.id, l.version));

  Future<bool> deleteResource(LessonResource r) =>
      _act(() => _repo.deleteResource(r.id));

  Future<bool> attach(Lesson l, PickedFile file, {String title = ''}) {
    if (file.size > maxUploadBytes) {
      actionError = const AppError(
        AppErrorKind.validation,
        'That file is larger than 10 MB.',
        AppErrorCode.fileLarger,
      );
      notifyListeners();
      return Future.value(false);
    }
    return _act(() async {
      var ticket = _ticket;
      final same =
          ticket != null &&
          _ticketLesson == l.id &&
          _ticketFile?.name == file.name &&
          _ticketFile?.size == file.size;
      if (!same) {
        ticket = await _repo.prepareResource(l.id, file);
        _ticket = ticket;
        _ticketLesson = l.id;
        _ticketFile = file;
      }
      await _repo.uploadBytes(ticket, file);
      await _repo.finalizeResource(ticket.resourceId, title.trim());
      _ticket = null;
      _ticketFile = null;
    });
  }

  Future<String?> urlFor(LessonResource r) async {
    try {
      return await _repo.signedUrl(r.path);
    } on Object catch (e) {
      actionError = AppError.from(e);
      notifyListeners();
      return null;
    }
  }

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
