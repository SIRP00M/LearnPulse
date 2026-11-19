import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/app_config.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/academic.dart';
import '../../core/formatting.dart';
import '../../core/language_selector.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/profile.dart';
import '../courses/courses_controller.dart' show LoadState;
import '../dashboard/dashboard.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_pages.dart';
import 'avatar_widgets.dart';
import '../staff/staff_page.dart';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return '?';
  final first = String.fromCharCode(list.first.runes.first);
  if (list.length == 1) return first.toUpperCase();
  return (first + String.fromCharCode(list.last.runes.first)).toUpperCase();
}

/// Profile tab: identity from the server profile plus the caller's own figures from the V7 aggregate RPCs.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.controller,
    required this.profile,
    required this.services,
    required this.onOpenCourses,
    this.active = true,
  });

  /// False while another tab is showing; a stale summary then reloads when this one becomes active.
  final bool active;
  final AuthController controller;
  final Profile profile;
  final AppServices services;
  final VoidCallback onOpenCourses;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final DashboardController<Object> _teacher;
  late final DashboardController<Object> _student;

  bool get _isTeacher => widget.profile.role == AppRole.teacher;

  @override
  void initState() {
    super.initState();
    final d = widget.services.dashboard;
    final bus = widget.services.summaries;
    _teacher = DashboardController<Object>(
      () async => (await d.teacher()) as Object,
      bus: bus,
    );
    _student = DashboardController<Object>(
      () async => (await d.student()) as Object,
      bus: bus,
    );
    final c = _isTeacher ? _teacher : _student;
    c.active = widget.active;
    (_isTeacher ? _student : _teacher).active =
        false; // the other role's RPC is never called
    c.load();
  }

  @override
  void didUpdateWidget(covariant ProfileTab old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      final c = _isTeacher ? _teacher : _student;
      widget.active ? c.activate() : c.deactivate();
    }
  }

  @override
  void dispose() {
    _teacher.dispose();
    _student.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final name = widget.profile.fullName;
    return ListenableBuilder(
      listenable: _isTeacher ? _teacher : _student,
      builder: (context, _) {
        final c = _isTeacher ? _teacher : _student;
        return RefreshIndicator(
          onRefresh: () => c.load(showSpinner: false),
          child: StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            secondary: [
              AcademicSection(
                title: _isTeacher
                    ? l.profileTeachingSummary
                    : l.profileLearningSummary,
                icon: Icons.insights_outlined,
                subtitle: _isTeacher
                    ? l.profileTeachingSubtitle
                    : l.profileLearningSubtitle,
                padded: true,
                children: [
                  if (c.state == LoadState.loading)
                    const SkeletonBlock()
                  else if (c.state == LoadState.error)
                    ErrorPanel(
                      error: c.error!,
                      onRetry: c.load,
                      full: false,
                      framed: false,
                    )
                  else ...[
                    if (c.error != null)
                      Text(
                        l.stateCouldNotRefresh(c.error!.localizedMessage(l)),
                        style: TextStyle(color: scheme.error),
                      ),
                    if (_isTeacher)
                      ..._teacherSummary(l, f, c.data as TeacherDashboard)
                    else
                      ..._studentSummary(l, f, c.data as StudentDashboard),
                  ],
                ],
              ),
              if (_isTeacher) ...[
                const SizedBox(height: Space.md),
                AcademicSection(
                  title: l.staffTitle,
                  icon: Icons.badge_outlined,
                  padded: true,
                  children: [
                    Text(l.staffSubtitle),
                    const SizedBox(height: Space.sm),
                    FilledButton.icon(
                      key: const Key('open-staff'),
                      icon: const Icon(Icons.badge_outlined),
                      label: Text(l.staffTitle),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StaffAttendancePage(
                            repository: widget.services.staff,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            children: [
              Container(
                padding: const EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  borderRadius: BorderRadius.circular(Radii.lg + 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTeacher
                          ? l.profileTeachingIdentity
                          : l.profileLearningIdentity,
                      style: text.labelMedium?.copyWith(
                        color: scheme.onSecondary.withValues(alpha: .85),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    AvatarCircle(
                      key: const Key('profile-avatar'),
                      repository: widget.services.avatars,
                      userId: '',
                      name: name,
                      path: widget.profile.avatarPath,
                      radius: 28,
                      backgroundColor: scheme.onSecondary,
                      foregroundColor: scheme.secondary,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      name.isEmpty ? l.profileNoName : name,
                      key: const Key('profile-name'),
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onSecondary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.controller.email ?? '',
                        key: const Key('profile-email'),
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSecondary.withValues(alpha: .9),
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Chip(
                      backgroundColor: Color.alphaBlend(
                        scheme.onSecondary.withValues(alpha: .12),
                        scheme.secondary,
                      ),
                      side: BorderSide(
                        color: scheme.onSecondary.withValues(alpha: .3),
                      ),
                      labelStyle: text.labelMedium?.copyWith(
                        color: scheme.onSecondary,
                      ),
                      avatar: Icon(
                        _isTeacher
                            ? Icons.school_outlined
                            : Icons.person_outline,
                        size: 16,
                        color: scheme.onSecondary,
                      ),
                      label: Text(_isTeacher ? l.roleTeacher : l.roleStudent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              AcademicCard(
                children: [
                  OutlinedButton.icon(
                    key: const Key('open-account'),
                    icon: const Icon(Icons.settings),
                    label: Text(l.profileAccountSettings),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountPage(
                          controller: widget.controller,
                          services: widget.services,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  const LanguageSelector(),
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    key: const Key('open-courses'),
                    icon: const Icon(Icons.menu_book),
                    label: Text(
                      _isTeacher
                          ? l.profileCoursesRosters
                          : l.profileCoursesAttendance,
                    ),
                    onPressed: widget.onOpenCourses,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _teacherSummary(
    AppLocalizations l,
    AppFormat f,
    TeacherDashboard d,
  ) => [
    metricGrid([
      MetricCard(
        '${d.coursesActive}',
        l.metricCoursesOwned,
        hint: d.coursesArchived == 0
            ? null
            : l.metricArchived(d.coursesArchived),
      ),
      MetricCard(f.number(d.activeStudents), l.metricActiveStudents),
      MetricCard(f.number(d.awaitingGrading), l.metricAwaitingGrading),
      MetricCard(
        percentLabel(d.attendanceRate, l: l, f: f),
        l.metricAttendanceRate,
        hint: l.metricOpenSessions(d.openSessions),
      ),
    ]),
    const SizedBox(height: Space.sm),
    Text(l.metricTeacherNote),
  ];

  List<Widget> _studentSummary(
    AppLocalizations l,
    AppFormat f,
    StudentDashboard d,
  ) => [
    metricGrid([
      MetricCard(f.number(d.coursesActive), l.metricEnrolledCourses),
      MetricCard(
        l.metricDoneOfPublished(d.done, d.published),
        l.metricAssignmentsDone,
        hint: l.metricSubmittedOrGraded,
      ),
      MetricCard(f.number(d.awaitingGrade), l.metricAwaitingGrade),
      MetricCard(
        f.number(d.graded),
        l.metricGraded,
        hint: d.averagePercent == null
            ? l.metricNoGradesYet
            : l.metricAverage(percentLabel(d.averagePercent, l: l, f: f)),
      ),
      MetricCard(f.number(d.needsRevision), l.metricReturnedRevision),
      MetricCard(
        percentLabel(d.attendanceRate, l: l, f: f),
        l.metricAttendanceRate,
      ),
    ]),
    const SizedBox(height: Space.sm),
    Text(l.metricStudentNote),
  ];
}

/// Account & settings: editable display name, read-only email, password link, privacy, About, confirmed sign-out.
class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.controller,
    required this.services,
  });
  final AuthController controller;
  final AppServices services;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.controller.profile?.fullName ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.updateDisplayName(_name.text);
  }

  Future<void> _confirmSignOut() async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountSignOutTitle),
        content: Text(l.accountSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-sign-out'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonSignOut),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final nav = Navigator.of(context);
    await widget.controller.signOut();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            secondary: [
              AcademicSection(
                title: l.profilePhotoTitle,
                icon: Icons.account_circle_outlined,
                children: [
                  AvatarPhotoSection(
                    controller: c,
                    avatars: widget.services.avatars,
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.accountTitle,
                icon: Icons.manage_accounts_outlined,
                children: [
                  ListTile(
                    leading: const AcademicIcon(Icons.email_outlined),
                    title: Text(l.accountRegisteredEmail),
                    subtitle: Text(c.email ?? l.commonUnknown),
                  ),
                  ListTile(
                    leading: const AcademicIcon(
                      Icons.badge_outlined,
                      category: 2,
                    ),
                    title: Text(l.accountRole),
                    subtitle: Text(
                      c.profile?.role == AppRole.teacher
                          ? l.roleTeacher
                          : l.roleStudent,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Text(l.accountManagedNote, style: text.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.accountPassword,
                icon: Icons.lock_outline,
                padded: true,
                children: [
                  OutlinedButton.icon(
                    key: const Key('change-password'),
                    icon: const Icon(Icons.lock_reset),
                    label: Text(l.accountEmailResetLink),
                    onPressed: c.busy ? null : c.sendPasswordChangeLink,
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.accountPrivacy,
                icon: Icons.privacy_tip_outlined,
                padded: true,
                children: [Text(l.accountPrivacyText)],
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.accountAbout,
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    leading: const AcademicIcon(
                      Icons.info_outline,
                      category: 3,
                    ),
                    title: const Text('LearnPulse'),
                    subtitle: Text(l.accountVersion(AppConfig.appVersion)),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              OutlinedButton.icon(
                key: const Key('sign-out'),
                icon: const Icon(Icons.logout),
                label: Text(l.commonSignOut),
                onPressed: c.busy ? null : _confirmSignOut,
              ),
            ],
            children: [
              AcademicPageHeader(
                eyebrow: l.accountEyebrow,
                icon: Icons.manage_accounts_outlined,
                title: l.profileAccountSettings,
                description: l.accountDescription,
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.languageTitle,
                icon: Icons.language,
                padded: true,
                children: [
                  const LanguageSelector(showLabel: false),
                  const SizedBox(height: Space.sm),
                  Text(l.languageHint, style: text.bodySmall),
                ],
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.accountPersonalDetails,
                icon: Icons.badge_outlined,
                padded: true,
                children: [
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('display-name'),
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: l.accountDisplayName,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: fieldValidator(validateFullName),
                          errorBuilder: validationErrorBuilder,
                          onFieldSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: Space.sm),
                        FilledButton(
                          key: const Key('save-name'),
                          onPressed: c.busy ? null : _save,
                          child: Text(l.accountSaveName),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (c.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(
                    c.error!.localizedMessage(l),
                    key: const Key('account-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (c.notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(
                    c.noticeText(l)!,
                    key: const Key('account-notice'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
