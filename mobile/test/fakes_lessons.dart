import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/lessons/lesson.dart';
import 'package:learn_pulse/features/lessons/lesson_repository.dart';

/// Scriptable in-memory lesson repository; records calls so tests can assert on them.
class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository({List<Lesson>? lessons, List<LessonResource>? resources})
    : lessons = lessons ?? [],
      resources = resources ?? [];

  final List<Lesson> lessons;
  final List<LessonResource> resources;
  final calls = <String>[];
  Object? error; // thrown once by the next mutating call
  Object? loadError;
  Object? uploadError; // thrown once by uploadBytes
  int _n = 0;

  void _maybeThrow() {
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
  }

  int _idx(String id) => lessons.indexWhere((l) => l.id == id);

  Lesson _copy(Lesson l, {String? title, String? body, LessonStatus? status}) =>
      Lesson(
        id: l.id,
        courseId: l.courseId,
        title: title ?? l.title,
        body: body ?? l.body,
        status: status ?? l.status,
        version: l.version + 1,
      );

  @override
  Future<List<Lesson>> listLessons(String courseId) async {
    if (loadError != null) throw loadError!;
    return List.of(lessons);
  }

  @override
  Future<List<LessonResource>> listResources(String courseId) async =>
      List.of(resources);

  @override
  Future<void> createLesson(String courseId, String title, String body) async {
    calls.add('create:$title');
    _maybeThrow();
    lessons.add(
      Lesson(
        id: 'l${++_n}',
        courseId: courseId,
        title: title,
        body: body,
        status: LessonStatus.draft,
        version: 1,
      ),
    );
  }

  @override
  Future<void> updateLesson(
    String lessonId,
    int expectedVersion, {
    String? title,
    String? body,
  }) async {
    calls.add('update:$lessonId:v$expectedVersion');
    _maybeThrow();
    final i = _idx(lessonId);
    lessons[i] = _copy(lessons[i], title: title, body: body);
  }

  @override
  Future<void> setPublished(
    String lessonId,
    int expectedVersion,
    bool publish,
  ) async {
    calls.add('publish:$lessonId:$publish');
    _maybeThrow();
    final i = _idx(lessonId);
    lessons[i] = _copy(
      lessons[i],
      status: publish ? LessonStatus.published : LessonStatus.draft,
    );
  }

  @override
  Future<void> deleteLesson(String lessonId, int expectedVersion) async {
    calls.add('delete:$lessonId');
    _maybeThrow();
    lessons.removeWhere((l) => l.id == lessonId);
    resources.removeWhere((r) => r.lessonId == lessonId);
  }

  @override
  Future<ResourceTicket> prepareResource(
    String lessonId,
    PickedFile file,
  ) async {
    calls.add('prepare:${file.name}');
    _maybeThrow();
    final id = 'r${++_n}';
    final path = 'c1/$lessonId/$id/${file.name}';
    resources.add(
      LessonResource(
        id: id,
        lessonId: lessonId,
        title: '',
        fileName: file.name,
        sizeBytes: file.size,
        path: path,
        attached: false,
      ),
    );
    return ResourceTicket(resourceId: id, path: path);
  }

  @override
  Future<void> uploadBytes(ResourceTicket ticket, PickedFile file) async {
    calls.add('upload:${ticket.resourceId}');
    final e = uploadError;
    if (e != null) {
      uploadError = null;
      throw e;
    }
  }

  @override
  Future<void> finalizeResource(String resourceId, String title) async {
    calls.add('finalize:$resourceId');
    _maybeThrow();
    final i = resources.indexWhere((r) => r.id == resourceId);
    final r = resources[i];
    resources[i] = LessonResource(
      id: r.id,
      lessonId: r.lessonId,
      title: title.isEmpty ? r.fileName : title,
      fileName: r.fileName,
      sizeBytes: r.sizeBytes,
      path: r.path,
      attached: true,
    );
  }

  @override
  Future<void> deleteResource(String resourceId) async {
    calls.add('deleteResource:$resourceId');
    _maybeThrow();
    resources.removeWhere((r) => r.id == resourceId);
  }

  @override
  Future<String> signedUrl(String path) async {
    calls.add('sign:$path');
    return 'https://example.test/signed/$path';
  }
}

Lesson fakeLesson({
  String id = 'l1',
  String title = 'Motion',
  String body = 'Newton',
  bool published = true,
  int version = 1,
}) => Lesson(
  id: id,
  courseId: 'c1',
  title: title,
  body: body,
  status: published ? LessonStatus.published : LessonStatus.draft,
  version: version,
);

LessonResource fakeResource({
  String id = 'r1',
  String lessonId = 'l1',
  String name = 'notes.pdf',
  String title = 'Notes',
}) => LessonResource(
  id: id,
  lessonId: lessonId,
  title: title,
  fileName: name,
  sizeBytes: 2048,
  path: 'c1/$lessonId/$id/$name',
  attached: true,
);
