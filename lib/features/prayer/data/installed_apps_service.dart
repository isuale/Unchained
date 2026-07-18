import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One launchable app on the device, as offered in the app-picker.
@immutable
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.icon,
  });

  final String packageName;
  final String label;

  /// The app's launcher icon as raw PNG bytes, or null if it couldn't be
  /// decoded. Rendered with `Image.memory`.
  final Uint8List? icon;
}

/// Dart wrapper over the native `unchained/apps` channel. Same try/catch-
/// returns-safe-default shape as [BlockingService] / [UninstallGuardService].
class InstalledAppsService {
  InstalledAppsService._();

  static const _channel = MethodChannel('unchained/apps');

  /// Every launchable app on the device (minus this app itself), alphabetical.
  /// Returns an empty list if the channel call fails.
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final raw = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (raw == null) return const [];
      return raw.map((e) {
        final map = (e as Map).cast<String, dynamic>();
        final b64 = (map['icon'] as String?) ?? '';
        return InstalledApp(
          packageName: (map['package'] as String?) ?? '',
          label: (map['label'] as String?) ?? '',
          icon: b64.isEmpty ? null : base64Decode(b64),
        );
      }).where((a) => a.packageName.isNotEmpty).toList();
    } catch (e, st) {
      debugPrint('InstalledAppsService.getInstalledApps failed: $e\n$st');
      return const [];
    }
  }
}

/// Loads the installed-app list once for the picker. Kept as a `FutureProvider`
/// so the picker shows a spinner while native renders every launcher icon.
final installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) {
  return InstalledAppsService.getInstalledApps();
});
