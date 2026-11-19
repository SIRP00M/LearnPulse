import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/app_error.dart';
import '../../core/formatting.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'lesson.dart';
import 'lessons_controller.dart';

ValidationIssue? validateLessonTitle(String? v) => validateTitle(v);

Widget _errorText(BuildContext context, LessonsController c) =>
    c.actionError == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Text(
          c.actionError!.text(context),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );

Future<void> _open(LessonsController c, LessonResource r) async {
  final url = await c.urlFor(r);
  if (url != null) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onOpen, this.onDelete});
  final LessonResource file;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.attach_file),
    title: Text(file.label, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      '${file.fileName} · ${AppFormat.of(context).fileSize(file.sizeBytes)}',
    ),
    onTap: onOpen,
    trailing: onDelete == null
        ? IconButton(
            tooltip: AppLocalizations.of(context).commonOpenNamed(file.label),
            icon: const Icon(Icons.open_in_new),
            onPressed: onOpen,
          )
        : IconButton(
            tooltip: AppLocalizations.of(context).commonRemoveNamed(file.label),
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
  );
}

/// "Lessons" block of the teacher's course page.
class TeacherLessonsSection extends StatefulWidget {
  const TeacherLessonsSection({
    super.key,
    required this.courseId,
    required this.services,
    required this.archived,
  });

  final String courseId;
  final AppServices services;
  final bool archived;

  @override
  State<TeacherLessonsSection> createState() => _TeacherLessonsSectionState();
}

class _TeacherLessonsSectionState extends State<TeacherLessonsSection> {
  late final LessonsController _c = LessonsController(
    widget.services.lessons,
    widget.courseId,
  );

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    _c.clearError();
    await showDialog<bool>(
      context: context,
      builder: (_) => _NewLessonDialog(controller: _c),
    );
  }

  Future<void> _openLesson(Lesson l) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherLessonPage(
          lessonId: l.id,
          controller: _c,
          services: widget.services,
        ),
      ),
    );
    if (mounted) _c.load(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      return AcademicSection(
        title: l.commonLessons,
        icon: Icons.menu_book_outlined,
        count: _c.state == LoadState.ready ? '${_c.lessons.length}' : null,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.lessonNew),
            onPressed: widget.archived ? null : _create,
          ),
        ],
        children: [
          if (_c.state == LoadState.loading)
            const SkeletonBlock()
          else if (_c.state == LoadState.error)
            ErrorPanel(
              error: _c.loadError!,
              onRetry: _c.load,
              full: false,
              framed: false,
            )
          else if (_c.lessons.isEmpty)
            EmptyPanel(
              icon: Icons.menu_book_outlined,
              title: l.lessonNoneYet,
              message: l.lessonEmptyTeacher,
              framed: false,
            )
          else
            for (final x in _c.lessons)
              StudioListItem(
                flat: true,
                title: x.title,
                detail: l.lessonFilesCount(_c.filesOf(x.id).length),
                icon: Icons.menu_book_outlined,
                status: StatusPill(
                  x.published ? l.commonPublished : l.commonDraft,
                  tone: x.published ? Tone.success : Tone.neutral,
                  icon: x.published ? null : Icons.edit_note,
                ),
                onTap: () => _openLesson(x),
              ),
        ],
      );
    },
  );
}

class _NewLessonDialog extends StatefulWidget {
  const _NewLessonDialog({required this.controller});
  final LessonsController controller;

  @override
  State<_NewLessonDialog> createState() => _NewLessonDialogState();
}

class _NewLessonDialogState extends State<_NewLessonDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await widget.controller.create(_title.text, _body.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(l.lessonNew),
        content: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _errorText(context, c),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l.commonTitle),
                  textCapitalization: TextCapitalization.sentences,
                  validator: fieldValidator(validateLessonTitle),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _body,
                  decoration: InputDecoration(labelText: l.lessonText),
                  maxLines: 5,
                  maxLength: maxLessonBody,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: c.busy ? null : () => Navigator.of(context).pop(),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: c.busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, Space.minTap),
            ),
            child: c.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.lessonCreateDraft),
          ),
        ],
      ),
    );
  }
}

/// One lesson as the teacher sees it: edit text, attach / remove files, publish or unpublish, delete.
class TeacherLessonPage extends StatefulWidget {
  const TeacherLessonPage({
    super.key,
    required this.lessonId,
    required this.controller,
    required this.services,
  });

  final String lessonId;
  final LessonsController controller;
  final AppServices services;

  @override
  State<TeacherLessonPage> createState() => _TeacherLessonPageState();
}

class _TeacherLessonPageState extends State<TeacherLessonPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: _l?.title);
  late final _body = TextEditingController(text: _l?.body);

  LessonsController get _c => widget.controller;
  Lesson? get _l => _c.lesson(widget.lessonId);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = _l;
    if (l == null || !_form.currentState!.validate()) return;
    await _c.update(l, _title.text, _body.text);
  }

  Future<void> _attach() async {
    final l = _l;
    if (l == null) return;
    try {
      final file = await widget.services.filePicker.pick();
      if (file != null) await _c.attach(l, file);
    } on Object catch (e) {
      _c.actionError = null;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.from(e).text(context))));
    }
  }

  Future<void> _delete(Lesson l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.lessonDeleteTitle),
          content: Text(l.lessonDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonDelete),
            ),
          ],
        );
      },
    );
    if (ok == true && await _c.delete(l) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final l = _l;
      final t = AppLocalizations.of(context);
      if (l == null) {
        return Scaffold(
          appBar: AppBar(title: Text(t.lessonTitle)),
          body: Center(child: Text(t.lessonGone)),
        );
      }
      final files = _c.filesOf(l.id);
      return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            Expanded(
              child: StudioPage(
                maxWidth: StudioLayout.maxWorkspace,
                secondary: [
                  AcademicSection(
                    title: t.commonFiles,
                    icon: Icons.attach_file,
                    count: '${files.length}',
                    children: [
                      if (files.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Text(t.lessonNoFilesAttached),
                        ),
                      for (final f in files)
                        _FileTile(
                          file: f,
                          onOpen: () => _open(_c, f),
                          onDelete: _c.busy ? null : () => _c.deleteResource(f),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: Text(t.lessonAttach),
                            onPressed: _c.busy ? null : _attach,
                          ),
                        ),
                      ),
                      if (_c.busy) const LinearProgressIndicator(),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  AcademicSection(
                    title: t.lessonPublication,
                    icon: Icons.visibility_outlined,
                    padded: true,
                    children: [
                      Text(t.lessonSaveFirst),
                      const SizedBox(height: Space.md),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: [
                          FilledButton.tonal(
                            onPressed: _c.busy
                                ? null
                                : () => _c.setPublished(l, !l.published),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(96, Space.minTap),
                            ),
                            child: Text(
                              l.published ? t.lessonUnpublish : t.commonPublish,
                            ),
                          ),
                          TextButton(
                            onPressed: _c.busy ? null : () => _delete(l),
                            child: Text(t.lessonDelete),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                children: [
                  _errorText(context, _c),
                  AcademicPageHeader(
                    eyebrow: t.lessonEditEyebrow,
                    icon: Icons.edit_note,
                    title: l.title,
                    description: l.published
                        ? t.lessonPublishedDesc
                        : t.lessonDraftDesc,
                  ),
                  const SizedBox(height: Space.md),
                  AcademicSection(
                    title: t.lessonContent,
                    icon: Icons.edit_note,
                    padded: true,
                    children: [
                      Form(
                        key: _form,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _title,
                              decoration: InputDecoration(
                                labelText: t.commonTitle,
                              ),
                              validator: fieldValidator(validateLessonTitle),
                              errorBuilder: validationErrorBuilder,
                            ),
                            const SizedBox(height: Space.md),
                            TextFormField(
                              controller: _body,
                              decoration: InputDecoration(
                                labelText: t.lessonText,
                              ),
                              maxLines: 8,
                              maxLength: maxLessonBody,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ),
            ),
            // In the body (not bottomNavigationBar) so it rises above the soft keyboard.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: FilledButton.icon(
                  onPressed: _c.busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(t.lessonSaveChanges),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// "Lessons" block of the student's course page (published lessons only; RLS enforces it).
class StudentLessonsSection extends StatefulWidget {
  const StudentLessonsSection({
    super.key,
    required this.courseId,
    required this.services,
    this.courseTitle,
  });

  final String? courseTitle;

  final String courseId;
  final AppServices services;

  @override
  State<StudentLessonsSection> createState() => _StudentLessonsSectionState();
}

class _StudentLessonsSectionState extends State<StudentLessonsSection> {
  late final LessonsController _c = LessonsController(
    widget.services.lessons,
    widget.courseId,
  );

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final t = AppLocalizations.of(context);
      return AcademicSection(
        title: t.commonLessons,
        icon: Icons.menu_book_outlined,
        count: _c.state == LoadState.ready ? '${_c.lessons.length}' : null,
        children: [
          if (_c.state == LoadState.loading)
            const SkeletonBlock()
          else if (_c.state == LoadState.error)
            ErrorPanel(
              error: _c.loadError!,
              onRetry: _c.load,
              full: false,
              framed: false,
            )
          else if (_c.lessons.isEmpty)
            EmptyPanel(
              icon: Icons.menu_book_outlined,
              title: t.lessonNoneYet,
              message: t.lessonEmptyStudent,
              framed: false,
            )
          else
            for (final x in _c.lessons)
              StudioListItem(
                flat: true,
                title: x.title,
                detail: t.lessonFilesCount(_c.filesOf(x.id).length),
                icon: Icons.menu_book_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentLessonPage(
                      lesson: x,
                      controller: _c,
                      courseTitle: widget.courseTitle,
                    ),
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class StudentLessonPage extends StatelessWidget {
  const StudentLessonPage({
    super.key,
    required this.lesson,
    required this.controller,
    this.courseTitle,
  });

  /// Context for the page header; omitted when the caller does not know the course.
  final String? courseTitle;

  final Lesson lesson;
  final LessonsController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final files = controller.filesOf(lesson.id);
      final t = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(),
        body: StudioPage(
          maxWidth: StudioLayout.reading,
          children: [
            _errorText(context, controller),
            AcademicPageHeader(
              eyebrow: courseTitle == null
                  ? t.lessonTitle
                  : t.lessonCourseEyebrow(courseTitle!),
              icon: Icons.menu_book_outlined,
              title: lesson.title,
              description: t.lessonReadExplore,
            ),
            const SizedBox(height: Space.md),
            AcademicSection(
              title: t.lessonContent,
              icon: Icons.article_outlined,
              padded: true,
              children: [
                SelectableText(
                  lesson.body.isEmpty ? t.lessonNoText : lesson.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.7),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            AcademicSection(
              title: t.commonFiles,
              icon: Icons.attach_file,
              count: '${files.length}',
              subtitle: t.lessonSupporting,
              padded: files.isEmpty,
              children: [
                if (files.isEmpty)
                  Text(t.lessonNoFiles)
                else
                  for (final f in files)
                    _FileTile(file: f, onOpen: () => _open(controller, f)),
              ],
            ),
          ],
        ),
      );
    },
  );
}
