import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/feed_guard_bridge.dart';

/// Raw 14-day history for the Progress tab's trend charts: blocked DNS
/// queries per day, plus feed-guard usage per day per target. A one-shot
/// fetch (not a stream) since both come from native SharedPreferences, not
/// a Drift table.
typedef AddictionTrendsData = ({
  Map<DateTime, int> blocked,
  Map<String, Map<DateTime, int>> feed,
});

final addictionTrendsProvider =
    FutureProvider.autoDispose<AddictionTrendsData>((ref) async {
  final blocked = await BlockingService.getBlockedHistory();
  final feed = await FeedGuardBridge.getHistory();
  return (blocked: blocked, feed: feed);
});
