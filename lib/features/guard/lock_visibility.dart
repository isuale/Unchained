import 'package:flutter/foundation.dart';

/// True while the full-screen Scripture lock ([ScriptureLockScreen]) is showing.
///
/// When the uninstall watchdog throws the lock up, the user must see ONLY the
/// 800-letter challenge — not the app's normal chrome. `main.dart` watches this
/// to hide the pinned owner-credit footer so the lock fills the whole screen,
/// instead of dropping the user into "the app".
final ValueNotifier<bool> scriptureLockActive = ValueNotifier<bool>(false);

/// True while a [PrayerGateScreen] is on the navigation stack.
///
/// The native watchdog can ask for the gate again while one is already up: any
/// system window appearing over it (a dim-screen overlay, for instance) counts
/// as a window change. Stacking a second gate would restart the prayer from
/// zero, so `main.dart` checks this before raising one. A plain bool, set in
/// `initState` rather than after a frame, so there is no gap to race through.
bool prayerGateOpen = false;
