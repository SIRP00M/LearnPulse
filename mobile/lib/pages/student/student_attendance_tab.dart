import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/student_attendance_service.dart';

class StudentAttendanceTab extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const StudentAttendanceTab({
    required this.courseId,
    required this.courseTitle,
    super.key,
  });

  @override
  State<StudentAttendanceTab> createState() =>
      _StudentAttendanceTabState();
}

class _StudentAttendanceTabState
    extends State<StudentAttendanceTab> {
  final StudentAttendanceService _service =
      StudentAttendanceService();

  final TextEditingController _codeController =
      TextEditingController();

  late Future<List<StudentAttendanceSession>>
      _sessionsFuture;

  late Future<List<StudentAttendanceEntry>>
      _historyFuture;

  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _sessionsFuture = _service.getCourseSessions(
      widget.courseId,
    );

    _historyFuture = _service.getMyAttendance(
      widget.courseId,
    );
  }

  Future<void> _refresh() async {
    setState(_loadData);

    await Future.wait<dynamic>([
      _sessionsFuture,
      _historyFuture,
    ]);
  }

  Future<void> _checkIn() async {
    final code =
        _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage(
        'Please enter the attendance code.',
      );

      return;
    }

    setState(() {
      _isCheckingIn = true;
    });

    try {
      final result =
          await _service.checkIn(code);

      if (!mounted) return;

      _codeController.clear();

      final message =
          result.status == 'late'
          ? 'Checked in successfully. You were marked late.'
          : 'Checked in successfully. You are present.';

      _showMessage(message);

      await _refresh();
    } on PostgrestException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to check in: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _sessionsFuture,
        _historyFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _AttendanceErrorView(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final sessions =
            snapshot.data?[0]
                    as List<StudentAttendanceSession>? ??
                const [];

        final history =
            snapshot.data?[1]
                    as List<StudentAttendanceEntry>? ??
                const [];

        final openSessions = sessions
            .where(
              (session) =>
                  session.status == 'open' &&
                  !session.hasEnded,
            )
            .toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            children: [
              _CheckInCard(
                controller: _codeController,
                isLoading: _isCheckingIn,
                onCheckIn: _checkIn,
              ),
              const SizedBox(height: 16),
              _AttendanceSummary(
                history: history,
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Open attendance',
                icon:
                    Icons.how_to_reg_rounded,
              ),
              const SizedBox(height: 10),
              if (openSessions.isEmpty)
                const _EmptyAttendanceCard(
                  icon: Icons.lock_clock_outlined,
                  title:
                      'No attendance is open',
                  message:
                      'Your teacher has not opened an attendance session.',
                )
              else
                for (final session
                    in openSessions) ...[
                  _OpenSessionCard(
                    session: session,
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Attendance history',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                const _EmptyAttendanceCard(
                  icon: Icons.fact_check_outlined,
                  title:
                      'No attendance history',
                  message:
                      'Your attendance records will appear here.',
                )
              else
                for (final entry
                    in history) ...[
                  _AttendanceHistoryCard(
                    entry: entry,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCheckIn;

  const _CheckInCard({
    required this.controller,
    required this.isLoading,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        colors.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.fact_check_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check attendance',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Enter the code from your teacher',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              enabled: !isLoading,
              autofocus: false,
              maxLength: 6,
              textCapitalization:
                  TextCapitalization.characters,
              textInputAction:
                  TextInputAction.done,
              onSubmitted: (_) {
                onCheckIn();
              },
              decoration: const InputDecoration(
                labelText: 'Attendance code',
                hintText: 'ABC123',
                prefixIcon:
                    Icon(Icons.key_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    isLoading ? null : onCheckIn,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.login_rounded,
                      ),
                label: Text(
                  isLoading
                      ? 'Checking in...'
                      : 'Check in',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  final List<StudentAttendanceEntry> history;

  const _AttendanceSummary({
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final present = history
        .where(
          (entry) =>
              entry.attendanceStatus ==
              'present',
        )
        .length;

    final late = history
        .where(
          (entry) =>
              entry.attendanceStatus == 'late',
        )
        .length;

    final absent = history
        .where(
          (entry) =>
              entry.attendanceStatus ==
              'absent',
        )
        .length;

    final excused = history
        .where(
          (entry) =>
              entry.attendanceStatus ==
              'excused',
        )
        .length;

    final attended = present + late;

    final rate = history.isEmpty
        ? 0.0
        : attended / history.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '$present',
                label: 'Present',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2EAD67),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value: '$late',
                label: 'Late',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFFF9F1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '$absent',
                label: 'Absent',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFE44E4E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value:
                    '${(rate * 100).round()}%',
                label: 'Attendance',
                icon: Icons.insights_rounded,
                color: const Color(0xFF805AD5),
                subtitle:
                    excused == 0
                    ? null
                    : '$excused excused',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpenSessionCard extends StatelessWidget {
  final StudentAttendanceSession session;

  const _OpenSessionCard({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final canCheckIn = session.isOpenNow;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(15),
        leading: CircleAvatar(
          child: Icon(
            canCheckIn
                ? Icons.lock_open_rounded
                : Icons.schedule_rounded,
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${_formatDate(session.startsAt)}\n'
          '${_formatTime(session.startsAt)}'
          ' – ${_formatTime(session.endsAt)}',
        ),
        isThreeLine: true,
        trailing: _SessionChip(
          label:
              canCheckIn
              ? 'Open now'
              : 'Not started',
          active: canCheckIn,
        ),
      ),
    );
  }
}

class _AttendanceHistoryCard
    extends StatelessWidget {
  final StudentAttendanceEntry entry;

  const _AttendanceHistoryCard({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(15),
        leading: CircleAvatar(
          child: Icon(
            _statusIcon(
              entry.attendanceStatus,
            ),
          ),
        ),
        title: Text(
          entry.sessionTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          entry.checkedInAt == null
              ? '${_formatDate(entry.startsAt)}'
                  '\nNo check-in time'
              : '${_formatDate(entry.startsAt)}'
                  '\nChecked in ${_formatTime(entry.checkedInAt!)}',
        ),
        isThreeLine: true,
        trailing: _AttendanceStatusChip(
          status: entry.attendanceStatus,
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'present' => Icons.check_rounded,
      'late' => Icons.schedule_rounded,
      'excused' =>
        Icons.event_available_rounded,
      _ => Icons.close_rounded,
    };
  }
}

class _AttendanceStatusChip
    extends StatelessWidget {
  final String status;

  const _AttendanceStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      'present' => (
          'Present',
          const Color(0xFF2EAD67),
        ),
      'late' => (
          'Late',
          const Color(0xFFFF9F1C),
        ),
      'excused' => (
          'Excused',
          const Color(0xFF246BFD),
        ),
      _ => (
          'Absent',
          const Color(0xFFE44E4E),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: data.$2.withAlpha(25),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$2,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  final String label;
  final bool active;

  const _SessionChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyAttendanceCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyAttendanceCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 30,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceErrorView
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AttendanceErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        28,
        70,
        28,
        32,
      ),
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 60,
        ),
        const SizedBox(height: 16),
        const Text(
          'Unable to load attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();

  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

String _formatTime(DateTime date) {
  final local = date.toLocal();

  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}