import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'dashboard.dart';
import 'dashboard_repository.dart';
import 'summary_bus.dart';

/// Loads one role's dashboard. A failed refresh keeps the figures already on screen; overlapping loads
/// collapse into one request (pull-to-refresh while loading is ignored). When a [SummaryBus] reports a
/// confirmed mutation the figures become stale: they reload at once while the screen is [active], otherwise
/// the next [activate] reloads them. A response that was requested before the mutation is discarded.
class DashboardController<T> extends ChangeNotifier {
  DashboardController(
    this._fetch, {
    SummaryBus? bus,
    this.topic = SummaryTopic.dashboard,
  }) : _bus = bus {
    bus?.addListener(_invalidate);
  }

  final Future<T> Function() _fetch;
  final SummaryBus? _bus;

  /// The invalidation topic this controller follows (the V7 figures by default).
  final SummaryTopic topic;
  bool _disposed = false;
  bool _loading = false;
  int _generation = 0;

  /// Whether the screen showing these figures is the visible tab.
  bool active = true;

  /// The figures on screen predate a mutation (or the last refresh failed) and should be reloaded.
  bool stale = false;

  LoadState state = LoadState.loading;
  T? data;
  AppError? error;

  void _invalidate() {
    if (!(_bus?.lastTopics.contains(topic) ?? true)) return;
    _generation++;
    stale = true;
    if (active) load(showSpinner: false);
  }

  /// Called when the tab becomes visible; reloads only if something is stale (one request, no loop).
  void activate() {
    active = true;
    if (stale) load(showSpinner: false);
  }

  void deactivate() => active = false;

  Future<void> load({bool showSpinner = true}) async {
    if (_loading) return;
    _loading = true;
    if (showSpinner && data == null) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      while (true) {
        final generation = _generation;
        stale = false;
        try {
          final result = await _fetch();
          if (generation == _generation) {
            data = result;
            error = null;
            state = LoadState.ready;
            break;
          }
        } on Object catch (e) {
          if (generation == _generation) {
            error = AppError.from(e);
            state = data == null ? LoadState.error : LoadState.ready;
            stale =
                data !=
                null; // keep the old figures, try again on the next activation
            break;
          }
        }
        // A mutation landed while this request was in flight: its answer may predate it.
        stale = true;
        if (!active) break;
      }
    } finally {
      _loading = false;
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bus?.removeListener(_invalidate);
    super.dispose();
  }
}

DashboardController<TeacherDashboard> teacherDashboardController(
  DashboardRepository r, {
  SummaryBus? bus,
}) => DashboardController<TeacherDashboard>(r.teacher, bus: bus);

DashboardController<StudentDashboard> studentDashboardController(
  DashboardRepository r, {
  SummaryBus? bus,
}) => DashboardController<StudentDashboard>(r.student, bus: bus);
