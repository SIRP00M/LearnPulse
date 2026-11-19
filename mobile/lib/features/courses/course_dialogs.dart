import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_error.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'course.dart';
import 'courses_controller.dart';

final _codePattern = RegExp(r'^[A-HJ-NP-Z2-9]{8}$');

ValidationIssue? validateJoinCode(String? v) {
  final code = (v ?? '').trim().toUpperCase();
  if (code.isEmpty) return ValidationIssue.joinCodeRequired;
  if (!_codePattern.hasMatch(code)) return ValidationIssue.joinCodeFormat;
  return null;
}

ValidationIssue? validateCourseTitle(String? v) => validateTitle(v);

/// Create-or-edit form. Pops with true when the action succeeded.
class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({super.key, required this.controller, this.existing});

  final CoursesController controller;
  final Course? existing;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final c = widget.controller;
    final existing = widget.existing;
    final bool ok;
    NewCourse? created;
    if (existing == null) {
      created = await c.create(_title.text, _description.text);
      ok = created != null;
    } else {
      ok = await c.update(
        existing.id,
        title: _title.text,
        description: _description.text,
      );
    }
    if (ok && mounted) Navigator.of(context).pop(created ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(widget.existing == null ? l.courseNew : l.courseEdit),
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
                  textInputAction: TextInputAction.next,
                  validator: fieldValidator(validateCourseTitle),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _description,
                  decoration: InputDecoration(
                    labelText: l.courseDescriptionOptional,
                  ),
                  maxLines: 3,
                  maxLength: 2000,
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
                : Text(widget.existing == null ? l.commonCreate : l.commonSave),
          ),
        ],
      ),
    );
  }
}

/// Shows the join code right after creation so the teacher can share it.
class JoinCodeDialog extends StatelessWidget {
  const JoinCodeDialog({super.key, required this.course});

  final NewCourse course;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.courseCreated),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.md),
          Text(l.courseShareCode),
          const SizedBox(height: Space.sm),
          SelectableText(
            course.joinCode,
            key: const Key('join-code'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(letterSpacing: 4),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy),
          label: Text(l.commonCopy),
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: course.joinCode)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonDone),
        ),
      ],
    );
  }
}

enum _JoinProblem { removed, invalid }

class JoinCourseDialog extends StatefulWidget {
  const JoinCourseDialog({super.key, required this.controller});

  final CoursesController controller;

  @override
  State<JoinCourseDialog> createState() => _JoinCourseDialogState();
}

class _JoinCourseDialogState extends State<JoinCourseDialog> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  AppError? _error;
  _JoinProblem? _problem;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final result = await widget.controller.join(_code.text);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _error = widget.controller.actionError;
        _problem = null;
      });
    } else if (result.outcome == JoinOutcome.joined) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = null;
        _problem = result.outcome == JoinOutcome.removed
            ? _JoinProblem.removed
            : _JoinProblem.invalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = AppLocalizations.of(context);
    final message = _error != null
        ? _error!.text(context)
        : switch (_problem) {
            _JoinProblem.removed => l.courseRemovedMsg,
            _JoinProblem.invalid => l.courseCodeInvalid,
            null => null,
          };
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(l.courseJoin),
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextFormField(
                controller: _code,
                decoration: InputDecoration(labelText: l.courseCodeLabel),
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(8),
                ],
                onFieldSubmitted: (_) => _submit(),
                validator: fieldValidator(validateJoinCode),
                errorBuilder: validationErrorBuilder,
              ),
            ],
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
                : Text(l.commonJoin),
          ),
        ],
      ),
    );
  }
}
