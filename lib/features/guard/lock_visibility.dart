import 'package:flutter/foundation.dart';

/// True while the full-screen Scripture lock ([ScriptureLockScreen]) is showing.
///
/// When the uninstall watchdog throws the lock up, the user must see ONLY the
/// 800-letter challenge — not the app's normal chrome. `main.dart` watches this
/// to hide the pinned owner-credit footer so the lock fills the whole screen,
/// instead of dropping the user into "the app".
final ValueNotifier<bool> scriptureLockActive = ValueNotifier<bool>(false);
