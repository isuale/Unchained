import 'package:home_widget/home_widget.dart';

/// Mirrors the prayer streak into the "Prayer Streak" home-screen widget (see
/// android/.../PrayerStreakWidgetProvider.kt). Fire-and-forget: nothing here
/// should ever throw into the caller — the in-app streak stays correct even
/// if no widget is pinned or the platform channel hiccups.
class PrayerStreakWidgetService {
  // Must be the fully-qualified class name, NOT just androidName: 'name'.
  // HomeWidget.updateWidget's `androidName` resolves against the app's
  // packageName (com.beunchained.app, the applicationId) but the widget's
  // real Kotlin package is com.unchained.unchained (see build.gradle.kts —
  // namespace and applicationId are deliberately different here). Passing
  // just the class name made every update silently throw "class not found",
  // swallowed by the catch below, so the widget never refreshed after a
  // prayer — only saveWidgetData's write ever landed.
  static const _qualifiedProvider =
      'com.unchained.unchained.PrayerStreakWidgetProvider';

  // Riverpod's WidgetRef.listen has no `fireImmediately`, so callers also
  // push the current value directly from build (see main.dart) alongside a
  // listener for later changes. This dedupes that double call on a build
  // where nothing actually changed.
  static int? _lastPushed;

  static Future<void> push(int streakDays) async {
    if (_lastPushed == streakDays) return;
    try {
      await HomeWidget.saveWidgetData<int>('streak_days', streakDays);
      await HomeWidget.updateWidget(qualifiedAndroidName: _qualifiedProvider);
      _lastPushed = streakDays;
    } catch (_) {
      // Best-effort only; leave _lastPushed alone so a later call retries.
    }
  }
}
