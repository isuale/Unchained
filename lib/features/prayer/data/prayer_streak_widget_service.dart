import 'package:home_widget/home_widget.dart';

/// Mirrors the prayer streak into the "Prayer Streak" home-screen widget (see
/// android/.../PrayerStreakWidgetProvider.kt). Fire-and-forget: nothing here
/// should ever throw into the caller — the in-app streak stays correct even
/// if no widget is pinned or the platform channel hiccups.
class PrayerStreakWidgetService {
  static const _androidProvider = 'PrayerStreakWidgetProvider';

  // Riverpod's WidgetRef.listen has no `fireImmediately`, so callers also
  // push the current value directly from build (see main.dart) alongside a
  // listener for later changes. This dedupes that double call on a build
  // where nothing actually changed.
  static int? _lastPushed;

  static Future<void> push(int streakDays) async {
    if (_lastPushed == streakDays) return;
    try {
      await HomeWidget.saveWidgetData<int>('streak_days', streakDays);
      await HomeWidget.updateWidget(androidName: _androidProvider);
      _lastPushed = streakDays;
    } catch (_) {
      // Best-effort only; leave _lastPushed alone so a later call retries.
    }
  }
}
