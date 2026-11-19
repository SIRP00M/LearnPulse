import 'package:flutter/material.dart';

import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/profile.dart';
import '../../app_services.dart';
import '../courses/courses_page.dart';
import '../demo/demo_pages.dart';
import '../dashboard/dashboard_pages.dart';
import '../profile/profile_pages.dart';
import '../tasks/tasks_page.dart';

/// Role-specific landing: a greeting from the server-loaded profile plus that role's course list.
class RoleHome extends StatefulWidget {
  const RoleHome({
    super.key,
    required this.controller,
    required this.profile,
    required this.services,
  });

  final AuthController controller;
  final Profile profile;
  final AppServices services;

  @override
  State<RoleHome> createState() => _RoleHomeState();
}

class _RoleHomeState extends State<RoleHome> {
  int _tab = 0;

  void _openDemoHost() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DemoHostPage(repository: widget.services.demo),
    ),
  );

  @override
  void initState() {
    super.initState();
    // Presenter Demo sign-in: go straight to the Live Demo console once, for a Teacher only.
    if (widget.controller.presenterIntent) {
      widget.controller.presenterIntent = false;
      if (widget.profile.role == AppRole.teacher) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openDemoHost();
        });
      }
    }
  }
  CourseArea _area = CourseArea.overview;
  void _openArea(CourseArea area) => setState(() {
    _area = area;
    _tab = 2;
  });

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = widget.profile;
    final services = widget.services;
    final teacher = profile.role == AppRole.teacher;
    final l = AppLocalizations.of(context);
    final name = profile.fullName.isEmpty
        ? l.homeNameFallback
        : profile.fullName;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail = constraints.maxWidth >= StudioLayout.medium;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 56,
            title: const Wordmark(),
            actions: [
              if (teacher)
                IconButton(
                  key: const Key('open-demo-host'),
                  tooltip: l.demoHostTooltip,
                  onPressed: _openDemoHost,
                  icon: const Icon(Icons.co_present_outlined),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: l.navOpenProfile,
                  onPressed: () => setState(() => _tab = 3),
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      name.isEmpty
                          ? '?'
                          : String.fromCharCode(name.runes.first).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: rail ? 88 : 0,
                  child: rail
                      ? SingleChildScrollView(
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: _tab,
                              labelType:
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      21
                                  ? NavigationRailLabelType.none
                                  : NavigationRailLabelType.all,
                              onDestinationSelected: (i) =>
                                  setState(() => _tab = i),
                              destinations: [
                                NavigationRailDestination(
                                  icon: Icon(Icons.dashboard_outlined),
                                  selectedIcon: Icon(Icons.dashboard),
                                  label: Text(l.navDashboard),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.checklist_rtl),
                                  selectedIcon: Icon(Icons.checklist_rtl),
                                  label: Text(l.navTasks),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.menu_book_outlined),
                                  selectedIcon: Icon(Icons.menu_book),
                                  label: Text(l.navCourses),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.account_circle_outlined),
                                  selectedIcon: Icon(Icons.account_circle),
                                  label: Text(l.navProfile),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      teacher
                          ? TeacherDashboardView(
                              services: services,
                              active: _tab == 0,
                              displayName: name,
                              onOpenCourses: () =>
                                  _openArea(CourseArea.overview),
                              onOpenArea: _openArea,
                              onOpenProfile: () => setState(() => _tab = 3),
                            )
                          : StudentDashboardView(
                              services: services,
                              active: _tab == 0,
                              onOpenTasks: () => setState(() => _tab = 1),
                              displayName: name,
                              onOpenCourses: () =>
                                  _openArea(CourseArea.overview),
                              onOpenArea: _openArea,
                              onOpenProfile: () => setState(() => _tab = 3),
                            ),
                      TasksTab(
                        key: ValueKey(
                          'tasks-${profile.role.name}-${profile.fullName}',
                        ),
                        profile: profile,
                        services: services,
                        active: _tab == 1,
                      ),
                      CoursesPage(
                        profile: profile,
                        services: services,
                        area: _area,
                        onAreaChanged: (area) => setState(() => _area = area),
                      ),
                      ProfileTab(
                        active: _tab == 3,
                        controller: controller,
                        profile: profile,
                        services: services,
                        onOpenCourses: () => setState(() => _tab = 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: rail
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: l.navDashboard,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.checklist_rtl),
                      selectedIcon: Icon(Icons.checklist_rtl),
                      label: l.navTasks,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: l.navCourses,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      selectedIcon: Icon(Icons.account_circle),
                      label: l.navProfile,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
