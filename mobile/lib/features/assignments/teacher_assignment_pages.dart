import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_services.dart';
import '../profile/avatar_widgets.dart';
import '../../core/formatting.dart';
import '../../core/states.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../core/academic.dart';
import '../courses/course_widgets.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'assignment.dart';
import 'assignment_controllers.dart';
import 'grade_submission_page.dart';

ValidationIssue? validateAssignmentTitle(String? v) => validateTitle(v);

ValidationIssue? validateMaxScore(String? v) {
  final n = int.tryParse((v ?? '').trim());
  if (n == null || n < 1 || n > 1000) return ValidationIssue.maxScoreRange;
  return null;
}

/// Create / edit form with optional deadline. Pops true on success.
class AssignmentFormDialog extends StatefulWidget {
  const AssignmentFormDialog({
    super.key,
    required this.controller,
    this.existing,
  });

  final AssignmentsController controller;
  final Assignment? existing;

  @override
  State<AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends State<AssignmentFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _instructions = TextEditingController(
    text: widget.existing?.instructions,
  );
  late final _score = TextEditingController(
    text: '${widget.existing?.maxScore ?? 100}',
  );
  late DateTime? _due = widget.existing?.dueAt?.toLocal();

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    _score.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? now),
    );
    if (time == null) return;
    setState(
      () => _due = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final c = widget.controller;
    final score = int.parse(_score.text.trim());
    final existing = widget.existing;
    final ok = existing == null
        ? await c.create(
            title: _title.text,
            instructions: _instructions.text,
            maxScore: score,
            dueAt: _due,
          )
        : await c.update(
            existing,
            title: _title.text,
            instructions: _instructions.text,
            maxScore: score,
            dueAt: _due,
            clearDue: _due == null && existing.dueAt != null,
          );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(widget.existing == null ? l.asgNewTitle : l.asgEditTitle),
        content: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Text(
                      c.actionError!.text(context),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l.commonTitle),
                  textCapitalization: TextCapitalization.sentences,
                  validator: fieldValidator(validateAssignmentTitle),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _instructions,
                  decoration: InputDecoration(labelText: l.asgInstructions),
                  maxLines: 4,
                  maxLength: 10000,
                ),
                const SizedBox(height: Space.sm),
                TextFormField(
                  controller: _score,
                  decoration: InputDecoration(labelText: l.asgMaxScoreLabel),
                  keyboardType: TextInputType.number,
                  validator: fieldValidator(validateMaxScore),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _due == null
                            ? l.asgNoDeadline
                            : l.asgDue(formatDateTime(_due!, f: f)),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDue,
                      child: Text(
                        _due == null ? l.asgSetDeadline : l.commonChange,
                      ),
                    ),
                    if (_due != null)
                      IconButton(
                        tooltip: l.asgRemoveDeadline,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _due = null),
                      ),
                  ],
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
                : Text(widget.existing == null ? l.asgSaveDraft : l.commonSave),
          ),
        ],
      ),
    );
  }
}

/// "Assignments" block of the teacher's course page.
class TeacherAssignmentsSection extends StatefulWidget {
  const TeacherAssignmentsSection({
    super.key,
    required this.courseId,
    required this.services,
    required this.archived,
  });

  final String courseId;
  final AppServices services;
  final bool archived;

  @override
  State<TeacherAssignmentsSection> createState() =>
      _TeacherAssignmentsSectionState();
}

class _TeacherAssignmentsSectionState extends State<TeacherAssignmentsSection> {
  late final AssignmentsController _c = AssignmentsController(
    widget.services.assignments,
    widget.courseId,
    summaries: widget.services.summaries,
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
      builder: (_) => AssignmentFormDialog(controller: _c),
    );
  }

  Future<void> _open(Assignment a) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherAssignmentPage(
          assignmentId: a.id,
          controller: _c,
          services: widget.services,
        ),
      ),
    );
    if (mounted) _c.load(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final f = AppFormat.of(context);
        return AcademicSection(
          title: l.commonAssignments,
          icon: Icons.assignment_outlined,
          count: _c.state == LoadState.ready
              ? '${_c.assignments.length}'
              : null,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.asgNewTitle),
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
            else if (_c.assignments.isEmpty)
              EmptyPanel(
                icon: Icons.assignment_outlined,
                title: l.asgNone,
                message: l.asgTeacherEmptyHint,
                framed: false,
              )
            else
              for (final a in _c.assignments)
                StudioListItem(
                  flat: true,
                  title: a.title,
                  icon: Icons.assignment_outlined,
                  detail: a.dueAt == null
                      ? l.asgNoDeadline
                      : l.asgDue(formatDateTime(a.dueAt!, f: f)),
                  status: StatusPill(
                    a.published ? l.commonPublished : l.commonDraft,
                    tone: a.published ? Tone.success : Tone.neutral,
                    icon: a.published ? null : Icons.edit_note,
                  ),
                  onTap: () => _open(a),
                ),
          ],
        );
      },
    );
  }
}

/// One assignment as the teacher sees it: details, publish/edit, and the submissions received.
class TeacherAssignmentPage extends StatefulWidget {
  const TeacherAssignmentPage({
    super.key,
    required this.assignmentId,
    required this.controller,
    required this.services,
  });

  final String assignmentId;
  final AssignmentsController controller;
  final AppServices services;

  @override
  State<TeacherAssignmentPage> createState() => _TeacherAssignmentPageState();
}

class _TeacherAssignmentPageState extends State<TeacherAssignmentPage> {
  late final SubmissionsController _s = SubmissionsController(
    widget.services.assignments,
    widget.assignmentId,
  );

  Assignment? get _a {
    for (final a in widget.controller.assignments) {
      if (a.id == widget.assignmentId) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _s.load();
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  Future<void> _publish(Assignment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.asgPublishTitle),
          content: Text(l.asgPublishBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonPublish),
            ),
          ],
        );
      },
    );
    if (ok == true) await widget.controller.publish(a);
  }

  Future<void> _openFile(UploadInfo u) async {
    final url = await _s.urlFor(u);
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _s]),
      builder: (context, _) {
        final a = _a;
        final scheme = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context);
        final f = AppFormat.of(context);
        if (a == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l.asgGone)),
          );
        }
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: l.asgEditTitle,
                icon: const Icon(Icons.edit),
                onPressed: widget.controller.busy
                    ? null
                    : () {
                        widget.controller.clearError();
                        showDialog<bool>(
                          context: context,
                          builder: (_) => AssignmentFormDialog(
                            controller: widget.controller,
                            existing: a,
                          ),
                        );
                      },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _s.load,
            child: StudioPage(
              padding: const EdgeInsets.all(Space.md),
              secondary: [
                AcademicCard(
                  children: [
                    Text(
                      l.asgSubmissionsCount(_s.submissions.length),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    if (_s.fileError != null)
                      Text(
                        _s.fileError!.text(context),
                        style: TextStyle(color: scheme.error),
                      ),
                    ..._submissionWidgets(a),
                  ],
                ),
              ],
              children: [
                AcademicPageHeader(
                  eyebrow: l.asgTeachingEyebrow,
                  icon: Icons.assignment_outlined,
                  category: 1,
                  title: a.title,
                  description: a.published ? l.asgReviewDesc : l.asgPrepareDesc,
                  meta: [
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          a.published ? l.commonPublished : l.commonDraft,
                          tone: a.published ? Tone.success : Tone.neutral,
                          icon: a.published ? null : Icons.edit_note,
                        ),
                        Text(l.asgMaxScore(a.maxScore)),
                      ],
                    ),
                    MetadataRow(
                      Icons.schedule,
                      a.dueAt == null
                          ? l.asgNoDeadline
                          : l.asgDue(formatDateTime(a.dueAt!, f: f)),
                    ),
                  ],
                  actions: [
                    if (!a.published)
                      FilledButton.icon(
                        icon: const Icon(Icons.publish),
                        label: Text(l.commonPublish),
                        onPressed: widget.controller.busy
                            ? null
                            : () => _publish(a),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
                AcademicSection(
                  title: l.asgBriefTitle,
                  icon: Icons.article_outlined,
                  padded: true,
                  children: [
                    Text(
                      a.instructions.isEmpty
                          ? l.asgNoInstructions
                          : a.instructions,
                    ),
                    if (widget.controller.actionError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: Text(
                          widget.controller.actionError!.text(context),
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _submissionWidgets(Assignment a) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    if (_s.state == LoadState.loading) {
      return [const SkeletonBlock()];
    }
    if (_s.state == LoadState.error) {
      return [
        ErrorPanel(
          error: _s.error!,
          onRetry: _s.load,
          full: false,
          framed: false,
        ),
      ];
    }
    if (!a.published) {
      return [Text(l.asgDraftsHidden)];
    }
    if (_s.submissions.isEmpty) {
      return [
        EmptyPanel(
          icon: Icons.inbox_outlined,
          title: l.asgNoSubmissions,
          message: l.asgNoSubmissionsHint,
          framed: false,
        ),
      ];
    }
    return [
      for (final s in _s.submissions)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarCircle(
                      repository: widget.services.avatars,
                      userId: s.studentId,
                      name: s.studentName ?? '',
                      lookup: true,
                      radius: 14,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        s.studentName ?? l.roleStudent,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                Text(
                  l.asgSubmittedVersion(
                    formatDateTime(s.submittedAt, f: f),
                    s.version,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (s.answer.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Text(s.answer),
                ],
                if (s.upload != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _openFile(s.upload!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 18),
                          const SizedBox(width: Space.xs),
                          Flexible(
                            child: Text(
                              '${s.upload!.fileName} (${f.fileSize(s.upload!.sizeBytes)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    statusLabel(l, s, a.maxScore),
                    tone: submissionTone(s.status),
                    icon: submissionIcon(s.status),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(Space.minTap * 2, Space.minTap),
                    ),
                    onPressed: () => _grade(a, s),
                    child: Text(
                      s.status == SubmissionStatus.submitted
                          ? l.asgGrade
                          : l.asgReview,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Future<void> _grade(Assignment a, Submission s) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GradeSubmissionPage(
          assignment: a,
          submission: s,
          services: widget.services,
        ),
      ),
    );
    if (mounted) _s.load(); // show the latest status and score
  }
}
