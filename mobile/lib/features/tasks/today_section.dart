import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'task.dart';
import 'tasks_controller.dart';
import 'tasks_page.dart';

/// Student dashboard: what needs doing today, from the same derived tasks as the Tasks tab (one status per task).
class TodayTasksSection extends StatefulWidget {
  const TodayTasksSection({
    super.key,
    required this.services,
    this.active = true,
    this.onOpenTasks,
  });
  final AppServices services;
  final bool active;
  final VoidCallback? onOpenTasks;

  @override
  State<TodayTasksSection> createState() => _TodayTasksSectionState();
}

class _TodayTasksSectionState extends State<TodayTasksSection> {
  late final TasksController _c = TasksController(
    widget.services.tasks,
    bus: widget.services.summaries,
  );

  @override
  void initState() {
    super.initState();
    _c.active = widget.active;
    _c.load();
  }

  @override
  void didUpdateWidget(covariant TodayTasksSection old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _c.activate() : _c.deactivate();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final open = [
          for (final t in _c.items)
            if (t.kind != TaskKind.attendanceSession) t,
        ];
        final todo = open.where((t) => t.needsAction).length;
        final shown = open.take(5).toList();
        return AcademicSection(
          title: l.relativeToday,
          icon: Icons.today_outlined,
          subtitle: _c.state == LoadState.ready
              ? (open.isEmpty
                    ? l.taskNothingDueToday
                    : l.taskTodoDone(todo, open.length - todo))
              : null,
          count: _c.state == LoadState.ready ? '${open.length}' : null,
          actions: [
            if (widget.onOpenTasks != null)
              OutlinedButton.icon(
                onPressed: widget.onOpenTasks,
                icon: const Icon(Icons.checklist_rtl),
                label: Text(l.taskAllTasks),
              ),
          ],
          children: [
            if (_c.state == LoadState.loading)
              const SkeletonBlock(rows: 2)
            else if (_c.state == LoadState.error)
              ErrorPanel(
                error: _c.error!,
                onRetry: _c.load,
                full: false,
                framed: false,
              )
            else if (shown.isEmpty)
              EmptyPanel(
                icon: Icons.celebration_outlined,
                title: l.taskAllClear,
                message: l.taskAllClearHint,
                framed: false,
              )
            else ...[
              for (final t in shown)
                TaskTile(
                  task: t,
                  onTap: () => openTask(context, widget.services, t),
                ),
              if (open.length > shown.length)
                Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Text(l.taskMoreInTasks(open.length - shown.length)),
                ),
            ],
          ],
        );
      },
    );
  }
}
