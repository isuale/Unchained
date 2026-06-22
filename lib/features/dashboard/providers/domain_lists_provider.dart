import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/domain/domain_lists.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';

/// The user's custom blocklist (extra domains they chose to block), parsed
/// from the stored newline string. Live-updates with the settings stream.
final customBlocklistProvider = Provider<List<String>>((ref) {
  final settings = ref.watch(blockingSettingsProvider).asData?.value;
  return parseDomainList(settings?.customBlocklist);
});

/// The user's custom allowlist (domains they chose to un-block). The hidden
/// built-in ~1000-domain safelist is NOT part of this — it lives natively and
/// is deliberately invisible here.
final customAllowlistProvider = Provider<List<String>>((ref) {
  final settings = ref.watch(blockingSettingsProvider).asData?.value;
  return parseDomainList(settings?.customAllowlist);
});

/// How many domains the native built-in porn blocklist contains (~1000),
/// shown as a summary at the top of the Blocklist tab.
final builtinBlocklistCountProvider = FutureProvider<int>((ref) {
  return BlockingService.builtinBlocklistCount();
});

enum DomainListResult { ok, invalid, duplicate }

/// Add/remove domains on the custom lists. Every change is persisted to the DB
/// and immediately pushed to the native VPN engine so it takes effect live.
class DomainListsActions {
  DomainListsActions(this._ref);
  final Ref _ref;

  BlockingSettingsRepository get _repo =>
      _ref.read(blockingSettingsRepositoryProvider);

  Future<void> _syncNative() async {
    final settings = await _repo.getSettings();
    await BlockingService.setUserLists(
      blocklist: parseDomainList(settings?.customBlocklist),
      allowlist: parseDomainList(settings?.customAllowlist),
    );
  }

  Future<DomainListResult> addToBlocklist(String raw) async {
    final domain = normalizeDomain(raw);
    if (domain == null) return DomainListResult.invalid;
    final settings = await _repo.getSettings();
    final current = parseDomainList(settings?.customBlocklist);
    if (current.contains(domain)) return DomainListResult.duplicate;
    await _repo.setCustomBlocklist([...current, domain]);
    await _syncNative();
    return DomainListResult.ok;
  }

  Future<void> removeFromBlocklist(String domain) async {
    final settings = await _repo.getSettings();
    final current = parseDomainList(settings?.customBlocklist);
    await _repo.setCustomBlocklist(current.where((d) => d != domain).toList());
    await _syncNative();
  }

  Future<DomainListResult> addToAllowlist(String raw) async {
    final domain = normalizeDomain(raw);
    if (domain == null) return DomainListResult.invalid;
    final settings = await _repo.getSettings();
    final current = parseDomainList(settings?.customAllowlist);
    if (current.contains(domain)) return DomainListResult.duplicate;
    await _repo.setCustomAllowlist([...current, domain]);
    await _syncNative();
    return DomainListResult.ok;
  }

  Future<void> removeFromAllowlist(String domain) async {
    final settings = await _repo.getSettings();
    final current = parseDomainList(settings?.customAllowlist);
    await _repo.setCustomAllowlist(current.where((d) => d != domain).toList());
    await _syncNative();
  }

  /// Pushes whatever is stored to the native engine. Call on app start so a
  /// freshly launched VPN service has the user's lists even before any edit.
  Future<void> syncToNative() => _syncNative();
}

final domainListsActionsProvider = Provider<DomainListsActions>((ref) {
  return DomainListsActions(ref);
});
