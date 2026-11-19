import 'package:flutter/foundation.dart';

/// What a mutation can make obsolete. Each screen listens for the topics it shows.
enum SummaryTopic { dashboard, progress, tasks, activities }

/// Tells screens that a confirmed mutation made their server figures obsolete.
/// It carries no data (a counter and the topics), so nothing about one account can leak into another; the
/// screens themselves always re-read the server (V7 dashboards, progress, tasks and activity RPCs).
class SummaryBus extends ChangeNotifier {
  int _revision = 0;
  Set<SummaryTopic> _last = const {...SummaryTopic.values};

  /// How many invalidations have happened; for tests and diagnostics.
  int get revision => _revision;

  /// Topics of the most recent invalidation (read by listeners inside their callback).
  Set<SummaryTopic> get lastTopics => _last;

  /// Invalidate [topics] (everything when omitted).
  void invalidate([Set<SummaryTopic>? topics]) {
    _revision++;
    _last = topics ?? const {...SummaryTopic.values};
    notifyListeners();
  }
}
