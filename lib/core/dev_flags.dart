/// Compile-time developer switches.
///
/// [kDevTools] gates hidden testing affordances (e.g. the long-press "reset
/// daily budget" on the social-feed rows, which bypasses the feed guard's 24h
/// anti-circumvention lock). It defaults to **false**, so a plain
/// `flutter build apk` / `flutter install` ships a normal, non-bypassable app.
///
/// Turn it on only for a local testing build:
///
///   flutter install --dart-define=DEV_TOOLS=true -d `device-id`
///
/// Because it's read from the environment at compile time, `false` builds have
/// the guarded code tree-shaken away entirely — a real user can never reach it.
const bool kDevTools = bool.fromEnvironment('DEV_TOOLS');
