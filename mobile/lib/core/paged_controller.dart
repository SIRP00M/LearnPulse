import 'package:flutter/foundation.dart';

import '../features/activities/activity.dart' show ServerPage;
import '../features/courses/courses_controller.dart' show LoadState;
import '../features/dashboard/summary_bus.dart';
import 'app_error.dart';

/// Keyset-paginated list loader with the same synchronisation rules as the dashboard summaries:
/// * a failed refresh keeps what is on screen (and the next activation retries once);
/// * a mutation on the [SummaryBus] topic marks it stale; it reloads at once while [active], otherwise on [activate];
/// * a response requested before the mutation (or before a reset) is discarded, so nothing obsolete is ever applied;
/// * pages are never silently truncated: [next] is the server cursor, [loadMore] continues it.
abstract class PagedController<T> extends ChangeNotifier {
  PagedController({SummaryBus? bus, this.topic = SummaryTopic.tasks})
    : _bus = bus {
    bus?.addListener(_onBus);
  }

  final SummaryBus? _bus;
  final SummaryTopic topic;

  /// One server page (the first when [cursor] is null).
  Future<ServerPage<T>> fetch(Map<String, dynamic>? cursor);

  LoadState state = LoadState.loading;
  List<T> items = const [];
  Map<String, dynamic>? next;
  int? total;
  AppError? error;
  bool loadingMore = false;

  /// Whether the screen is the visible one.
  bool active = true;
  bool stale = false;

  int _generation = 0;
  bool _loading = false;
  bool _disposed = false;

  void _onBus() {
    if (!(_bus?.lastTopics.contains(topic) ?? true)) return;
    _generation++;
    stale = true;
    if (active) load(showSpinner: false);
  }

  void activate() {
    active = true;
    if (stale) load(showSpinner: false);
  }

  void deactivate() => active = false;

  /// The view parameters changed: forget the rows and start again (an in-flight request is discarded).
  void reset() {
    _generation++;
    items = const [];
    next = null;
    total = null;
    error = null;
    state = LoadState.loading;
    notifyListeners();
    load();
  }

  Future<void> load({bool showSpinner = true}) async {
    if (_loading) return;
    _loading = true;
    if (showSpinner && items.isEmpty && state != LoadState.loading) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      while (true) {
        final generation = _generation;
        stale = false;
        try {
          final page = await fetch(null);
          if (generation == _generation) {
            items = page.items;
            next = page.next;
            total = page.total;
            error = null;
            state = LoadState.ready;
            break;
          }
        } on Object catch (e) {
          if (generation == _generation) {
            error = AppError.from(e);
            state = items.isEmpty ? LoadState.error : LoadState.ready;
            stale = items.isNotEmpty;
            break;
          }
        }
        stale = true;
        if (!active) break;
      }
    } finally {
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = next;
    if (cursor == null || loadingMore || _loading) return;
    loadingMore = true;
    notifyListeners();
    final generation = _generation;
    try {
      final page = await fetch(cursor);
      if (generation == _generation) {
        items = [...items, ...page.items];
        next = page.next;
        error = null;
      }
    } on Object catch (e) {
      if (generation == _generation) error = AppError.from(e);
    } finally {
      loadingMore = false;
    }
    notifyListeners();
  }

  /// Follow the cursor to the end (bounded) for views that must show a whole window, e.g. a week grid.
  Future<void> loadAll({int maxPages = 20}) async {
    for (var i = 0; i < maxPages && next != null && error == null; i++) {
      await loadMore();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bus?.removeListener(_onBus);
    super.dispose();
  }
}
