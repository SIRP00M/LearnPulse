import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../core/academic.dart';
import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../courses/course_widgets.dart';
import 'assignment.dart';
import 'grading_controller.dart';

Tone submissionTone(SubmissionStatus s) => switch (s) {
  SubmissionStatus.submitted => Tone.attention,
  SubmissionStatus.graded => Tone.success,
  SubmissionStatus.returned => Tone.info,
};

IconData submissionIcon(SubmissionStatus s) => switch (s) {
  SubmissionStatus.submitted => Icons.hourglass_empty,
  SubmissionStatus.graded => Icons.check_circle_outline,
  SubmissionStatus.returned => Icons.undo,
};

String statusLabel(AppLocalizations l, Submission s, int maxScore) =>
    switch (s.status) {
      SubmissionStatus.submitted => l.metricAwaitingGrading,
      SubmissionStatus.graded => l.asgGradedScore(s.score ?? 0, maxScore),
      SubmissionStatus.returned => l.asgReturnedForRevision,
    };

/// Teacher view of one submission: the work, the grade and feedback form, return for revision, history.
class GradeSubmissionPage extends StatefulWidget {
  const GradeSubmissionPage({
    super.key,
    required this.assignment,
    required this.submission,
    required this.services,
  });

  final Assignment assignment;
  final Submission submission;
  final AppServices services;

  @override
  State<GradeSubmissionPage> createState() => _GradeSubmissionPageState();
}

class _GradeSubmissionPageState extends State<GradeSubmissionPage> {
  late final GradingController _c = GradingController(
    widget.services.assignments,
    widget.assignment,
    widget.submission,
    summaries: widget.services.summaries,
  );
  late final TextEditingController _score = TextEditingController(
    text: _c.scoreText,
  );
  late final TextEditingController _feedback = TextEditingController(
    text: _c.feedback,
  );
  bool _fileError = false;

  @override
  void initState() {
    super.initState();
    _c.reload(); // always start from the server's current version
  }

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _openFile(UploadInfo u) async {
    try {
      final url = await widget.services.assignments.signedUrl(u.path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _fileError = false);
    } on Object catch (_) {
      if (mounted) setState(() => _fileError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final s = _c.submission;
        final scheme = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context);
        final f = AppFormat.of(context);
        final notice = _c.noticeText(l);
        return Scaffold(
          appBar: AppBar(),
          body: StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            children: [
              AcademicPageHeader(
                eyebrow: l.gradeReviewEyebrow(a.title),
                icon: Icons.rate_review_outlined,
                category: 1,
                title: s.studentName ?? l.gradeStudentSubmission,
                description: l.gradeReadDesc,
              ),
              const SizedBox(height: Space.md),
              AcademicSummary(
                title: l.gradeStatusTitle,
                status: StatusPill(
                  statusLabel(l, s, a.maxScore),
                  key: const Key('status-chip'),
                  tone: submissionTone(s.status),
                  icon: submissionIcon(s.status),
                ),
                stats: [
                  (label: l.gradeVersion, value: '${s.version}'),
                  (label: l.gradeMaxScore, value: '${a.maxScore}'),
                ],
                footer: Text(
                  l.gradeSubmittedAt(formatDateTime(s.submittedAt, f: f)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: Space.md),
              StudioColumns(
                primary: AcademicCard(
                  children: [
                    Text(
                      l.gradeStudentAnswer,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    const SizedBox(height: Space.xs),
                    Container(
                      padding: const EdgeInsets.all(Space.md),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border(
                          left: BorderSide(
                            color: scheme.primary,
                            width: Space.xs,
                          ),
                        ),
                      ),
                      child: SelectableText(
                        s.answer.isEmpty ? l.gradeNoText : s.answer,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
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
                                  s.upload!.fileName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_fileError)
                      Text(
                        l.errorOpenFile,
                        style: TextStyle(color: scheme.error),
                      ),
                    if (notice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Text(
                          notice,
                          key: const Key('grade-notice'),
                          style: TextStyle(color: scheme.primary),
                        ),
                      ),
                    if (_c.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Text(
                          _c.error!.text(context),
                          key: const Key('grade-error'),
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    if (_c.needsReload)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: OutlinedButton(
                          onPressed: _c.reload,
                          child: Text(l.gradeReloadLatest),
                        ),
                      ),
                  ],
                ),
                secondary: AcademicCard(
                  children: [
                    if (!_c.canAct)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(Space.md),
                          child: Text(
                            '${l.gradeWaiting}'
                            '${(s.feedback ?? '').isEmpty ? '' : '\n\n${l.gradeYourFeedback(s.feedback!)}'}',
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        l.gradeAndFeedback,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Space.sm),
                      Text(l.gradeHint),
                      const SizedBox(height: Space.sm),
                      Text(
                        l.gradeScore,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: Space.xs),
                      TextField(
                        controller: _score,
                        enabled: !_c.busy,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l.gradeScoreRangeLabel(a.maxScore),
                          suffixText: '/ ${a.maxScore}',
                        ),
                        onChanged: _c.setScore,
                      ),
                      const SizedBox(height: Space.md),
                      Text(
                        l.gradeFeedbackToStudent,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: Space.xs),
                      TextField(
                        controller: _feedback,
                        enabled: !_c.busy,
                        minLines: 3,
                        maxLines: 8,
                        maxLength: maxFeedbackLength,
                        decoration: InputDecoration(
                          labelText: l.gradeFeedback,
                          alignLabelWithHint: true,
                        ),
                        onChanged: _c.setFeedback,
                      ),
                      const SizedBox(height: Space.sm),
                      FilledButton(
                        onPressed: _c.busy ? null : _c.saveGrade,
                        child: _c.busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                s.status == SubmissionStatus.graded
                                    ? l.gradeSaveNew
                                    : l.gradeSave,
                              ),
                      ),
                      const SizedBox(height: Space.sm),
                      OutlinedButton(
                        onPressed: _c.busy ? null : _c.returnForRevision,
                        child: Text(l.gradeReturn),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.gradeHistory,
                icon: Icons.history,
                padded: _c.history.isEmpty,
                children: [
                  if (_c.history.isEmpty)
                    Text(l.gradeNoHistory)
                  else
                    for (final e in _c.history)
                      ListTile(
                        dense: true,
                        title: Text(
                          e.action == 'graded'
                              ? l.asgGradedScore(e.score ?? 0, a.maxScore)
                              : l.asgReturnedForRevision,
                        ),
                        subtitle: Text(
                          '${formatDateTime(e.createdAt, f: f)}${e.feedback.isEmpty ? '' : '\n${e.feedback}'}',
                        ),
                      ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
