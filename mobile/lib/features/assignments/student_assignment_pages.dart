import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_services.dart';
import '../../core/formatting.dart';
import '../../core/states.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../core/academic.dart';
import '../courses/course_widgets.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'assignment.dart';
import 'grade_submission_page.dart'
    show submissionIcon, submissionTone, statusLabel;
import 'assignment_controllers.dart';

/// "Assignments" block of the student's course page (published only; drafts never reach the client).
class StudentAssignmentsSection extends StatefulWidget {
  const StudentAssignmentsSection({
    super.key,
    required this.courseId,
    required this.services,
  });

  final String courseId;
  final AppServices services;

  @override
  State<StudentAssignmentsSection> createState() =>
      _StudentAssignmentsSectionState();
}

class _StudentAssignmentsSectionState extends State<StudentAssignmentsSection> {
  late final AssignmentsController _c = AssignmentsController(
    widget.services.assignments,
    widget.courseId,
    student: true,
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

  Widget _pill(AppLocalizations l, Assignment a, DateTime now) {
    final s = _c.mine[a.id];
    final label = _chipLabel(l, a, now);
    if (s == null) {
      return StatusPill(
        label,
        icon: a.isClosed(now)
            ? Icons.lock_outline
            : Icons.radio_button_unchecked,
      );
    }
    return StatusPill(
      label,
      tone: submissionTone(s.status),
      icon: submissionIcon(s.status),
    );
  }

  String _chipLabel(AppLocalizations l, Assignment a, DateTime now) {
    final s = _c.mine[a.id];
    if (s == null) return a.isClosed(now) ? l.commonClosed : l.asgNotSubmitted;
    return switch (s.status) {
      SubmissionStatus.graded => l.asgGradedScore(s.score ?? 0, a.maxScore),
      SubmissionStatus.returned => l.statusReturned,
      SubmissionStatus.submitted => l.statusSubmitted,
    };
  }

  Future<void> _open(Assignment a) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentAssignmentPage(
          assignment: a,
          existing: _c.mine[a.id],
          services: widget.services,
        ),
      ),
    );
    if (mounted) _c.load(showSpinner: false); // reflect what was saved
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final now = DateTime.now();
        final l = AppLocalizations.of(context);
        final f = AppFormat.of(context);
        return AcademicSection(
          title: l.commonAssignments,
          icon: Icons.assignment_outlined,
          count: _c.state == LoadState.ready
              ? '${_c.assignments.length}'
              : null,
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
                message: l.asgStudentEmptyHint,
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
                  status: _pill(l, a, now),
                  onTap: () => _open(a),
                ),
          ],
        );
      },
    );
  }
}

/// The student's view of one assignment: instructions, the saved submission, and the answer form.
class StudentAssignmentPage extends StatefulWidget {
  const StudentAssignmentPage({
    super.key,
    required this.assignment,
    required this.existing,
    required this.services,
  });

  final Assignment assignment;
  final Submission? existing;
  final AppServices services;

  @override
  State<StudentAssignmentPage> createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
  late final SubmissionController _c = SubmissionController(
    widget.services.assignments,
    widget.services.filePicker,
    widget.assignment,
    existing: widget.existing,
    summaries: widget.services.summaries,
  );
  late final TextEditingController _answer = TextEditingController(
    text: _c.answer,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Always show the server's current state (e.g. after an app restart or a change on another device).
  Future<void> _refresh() async {
    await _c.reload();
    if (!mounted) return;
    if (_answer.text.isEmpty && _c.existing != null) {
      _answer.text = _c.existing!.answer;
      _c.setAnswer(_answer.text);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _answer.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _openExisting(UploadInfo u) async {
    try {
      final url = await widget.services.assignments.signedUrl(u.path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorOpenFile)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context);
        final f = AppFormat.of(context);
        final notice = _c.noticeText(l);
        final saved = _c.existing;
        final returned = saved?.status == SubmissionStatus.returned;
        final graded = saved?.status == SubmissionStatus.graded;
        // A returned submission can be revised even after the deadline (the teacher reopened it).
        final closed = a.isClosed(DateTime.now()) && !returned;
        return Scaffold(
          appBar: AppBar(),
          body: _loading
              ? const SkeletonPage()
              : StudioPage(
                  secondary: [
                    AcademicCard(
                      children: [
                        if (saved != null &&
                            saved.status != SubmissionStatus.submitted) ...[
                          Card(
                            key: const Key('result-card'),
                            child: Padding(
                              padding: const EdgeInsets.all(Space.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    graded
                                        ? l.asgResultGraded(
                                            saved.score ?? 0,
                                            a.maxScore,
                                          )
                                        : l.asgReturnedForRevision,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  if ((saved.feedback ?? '').isNotEmpty) ...[
                                    const SizedBox(height: Space.xs),
                                    Text(l.asgFeedbackLine(saved.feedback!)),
                                  ],
                                  const SizedBox(height: Space.xs),
                                  Text(
                                    graded
                                        ? l.asgGradedLocked
                                        : l.asgReviseResubmit,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.md),
                        ],
                        if (saved != null) ...[
                          Text(
                            l.asgSavedSubmission,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            l.asgSavedLine(
                              formatDateTime(saved.submittedAt, f: f),
                              saved.version,
                            ),
                            key: const Key('saved-version'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (saved.upload != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => _openExisting(saved.upload!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attach_file, size: 18),
                                    const SizedBox(width: Space.xs),
                                    Flexible(
                                      child: Text(
                                        saved.upload!.fileName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: Space.md),
                        ],
                        if (notice != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: Text(
                              notice,
                              key: const Key('submit-notice'),
                              style: TextStyle(color: scheme.primary),
                            ),
                          ),
                        if (_c.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: Text(
                              _c.error!.text(context),
                              key: const Key('submit-error'),
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        if (_c.needsReload)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: OutlinedButton(
                              onPressed: _c.reload,
                              child: Text(l.asgReload),
                            ),
                          ),
                        if (!closed && !graded) ..._form(context, saved),
                      ],
                    ),
                  ],
                  children: [
                    AcademicPageHeader(
                      eyebrow: l.asgEyebrowWorkspace,
                      icon: Icons.assignment_outlined,
                      category: 1,
                      title: a.title,
                      meta: [
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: [
                            StatusPill(
                              a.dueAt == null
                                  ? l.asgNoDeadline
                                  : l.asgDue(formatDateTime(a.dueAt!, f: f)),
                              icon: Icons.schedule,
                              tone: closed ? Tone.danger : Tone.info,
                            ),
                            StatusPill(
                              l.asgMaxScore(a.maxScore),
                              icon: Icons.grading,
                            ),
                            if (saved != null)
                              StatusPill(
                                statusLabel(l, saved, a.maxScore),
                                tone: submissionTone(saved.status),
                                icon: submissionIcon(saved.status),
                              ),
                          ],
                        ),
                        if (closed)
                          Text(
                            l.asgDeadlinePassed,
                            style: TextStyle(color: scheme.error),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    AcademicSection(
                      title: l.asgBrief,
                      icon: Icons.article_outlined,
                      padded: true,
                      children: [
                        Text(
                          a.instructions.isEmpty
                              ? l.asgNoInstructions
                              : a.instructions,
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<Widget> _form(BuildContext context, Submission? saved) {
    final busy = _c.busy;
    final l = AppLocalizations.of(context);
    final label = switch (_c.phase) {
      SubmitPhase.uploading => l.asgUploading,
      SubmitPhase.submitting => l.asgSaving,
      SubmitPhase.idle => saved == null ? l.asgSubmit : l.asgResubmit,
    };
    return [
      Text(l.asgYourResponse, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: Space.sm),
      Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Text(
          saved == null ? l.asgFirstHint : l.asgUpdateHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      TextField(
        controller: _answer,
        enabled: !busy,
        minLines: 6,
        maxLines: 10,
        maxLength: 20000,
        decoration: InputDecoration(
          labelText: l.asgYourAnswer,
          alignLabelWithHint: true,
          hintText: l.asgAnswerHint,
        ),
        onChanged: _c.setAnswer,
      ),
      const SizedBox(height: Space.sm),
      if (_c.picked != null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(_c.picked!.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              l.asgUploadPrivately(
                AppFormat.of(context).fileSize(_c.picked!.size),
              ),
            ),
            trailing: IconButton(
              tooltip: l.asgRemoveAttachmentTip,
              icon: const Icon(Icons.close),
              onPressed: busy ? null : _c.removePicked,
            ),
          ),
        )
      else
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: Text(
            saved?.upload != null ? l.asgReplaceFile : l.asgAttachFile,
          ),
          onPressed: busy ? null : _c.pickFile,
        ),
      if (saved?.upload != null && _c.picked == null)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _c.clearAttachment,
          onChanged: busy ? null : (v) => _c.setClearAttachment(v ?? false),
          title: Text(l.asgRemoveSaved),
        ),
      const SizedBox(height: Space.md),
      Text(l.asgSavedOnSubmit, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: Space.sm),
      FilledButton(
        onPressed: busy ? null : _c.submit,
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Space.sm),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    ];
  }
}
