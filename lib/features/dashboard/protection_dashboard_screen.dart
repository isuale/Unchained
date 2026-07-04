import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
import 'package:unchained/features/dashboard/widgets/big_cta_button.dart';
import 'package:unchained/features/dashboard/widgets/dashboard_header.dart';
import 'package:unchained/features/dashboard/widgets/master_toggle_card.dart';
import 'package:unchained/features/dashboard/widgets/pill_selector.dart';
import 'package:unchained/features/dashboard/widgets/section_title.dart';
import 'package:unchained/features/dashboard/widgets/toggle_row.dart';
import 'package:unchained/features/guard/presentation/scripture_lock_screen.dart';
import 'package:unchained/features/guard/presentation/uninstall_protection_card.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';
import 'package:unchained/l10n/app_localizations.dart';

class ProtectionDashboardScreen extends ConsumerWidget {
  const ProtectionDashboardScreen({super.key});

  static const _bgTop = Color(0xFF000000);
  static const _bgBottom = Color(0xFF050812);
  static const _separator = Color(0xFF1A2238);
  static const _green = Color(0xFF00D26A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncSettings = ref.watch(blockingSettingsProvider);
    final activePlan = ref.watch(activePlanProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
      child: asyncSettings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E5FFF)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading settings: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (s) => _DashboardBody(
          settings: s,
          activePlan: activePlan,
          l: l,
        ),
      ),
    );
  }

  static Color get separator => _separator;
  static Color get green => _green;
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.settings,
    required this.activePlan,
    required this.l,
  });

  final BlockingSetting settings;
  final ActivePlan? activePlan;
  final AppLocalizations l;

  void _toggle(WidgetRef ref, String field, bool value) {
    ref.read(blockingSettingsActionsProvider.notifier).toggle(field, value);
  }

  /// Prevent-uninstall is more than a DB flag: it needs the system overlay +
  /// accessibility permissions and a native guard. Flipping the switch here runs
  /// the exact same flow as the Settings screen — turning *on* opens the
  /// permission-asking activation card, turning *off* is gated by the scripture
  /// lock — then mirrors the real native guard state back into the DB flag the
  /// switch reflects.
  Future<void> _togglePreventUninstall(
      BuildContext context, WidgetRef ref, bool value) async {
    if (value) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0A0E18),
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(child: UninstallProtectionCard()),
          ),
        ),
      );
    } else {
      // Turning protection off must pass the same scripture challenge.
      await context.push('/lock', extra: LockMode.disable);
    }
    if (!context.mounted) return;
    final enabled = await UninstallGuardService.isGuardEnabled();
    ref
        .read(blockingSettingsActionsProvider.notifier)
        .toggle('preventUninstall', enabled);
  }

  Future<void> _toggleMaster(
      BuildContext context, WidgetRef ref, bool value) async {
    final notifier = ref.read(blockingSettingsActionsProvider.notifier);
    final status = ref.read(commitmentStatusProvider);
    final mode = commitmentModeFromString(settings.commitmentMode);
    final l = AppLocalizations.of(context)!;

    ProtectionToggleResult result;
    if (value) {
      if (!status.isActive) {
        if (mode == CommitmentMode.none) {
          // No plan-driven lock (e.g. free trial) — just turn protection on.
          result = await notifier.toggleProtection(true);
        } else {
          // Turning protection on for the first time starts the commitment.
          final confirmed = await _confirmCommitment(
              context, l, mode, settings.commitmentTotalDays);
          if (confirmed != true) return;
          result = await notifier.startCommitment();
        }
      } else {
        // Re-enabling during a break — no new commitment, just turn it on.
        result = await notifier.toggleProtection(true);
      }
    } else {
      result = await notifier.toggleProtection(false);
    }

    if (!context.mounted) return;
    String? msg;
    if (result == ProtectionToggleResult.permissionDenied) {
      msg = l.protection_permission_needed;
    } else if (result == ProtectionToggleResult.failed) {
      msg = l.protection_start_failed;
    } else if (result == ProtectionToggleResult.locked) {
      msg = status.isPermanent
          ? l.commitment_forever_toast
          : l.commitment_locked_toast(status.daysLeft);
    }
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0A0F1C),
        ),
      );
    }
  }

  /// One-time warning the user must accept before the lock engages. The wording
  /// depends on the plan's commitment [mode].
  Future<bool?> _confirmCommitment(
      BuildContext context, AppLocalizations l, CommitmentMode mode, int days) {
    final title = mode == CommitmentMode.forever
        ? l.commitment_warning_forever_title
        : l.commitment_warning_title;
    final body = switch (mode) {
      CommitmentMode.forever => l.commitment_warning_forever_body,
      CommitmentMode.cycle => l.commitment_warning_cycle_body(days),
      _ => l.commitment_warning_fixed_body(days),
    };
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E18),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          body,
          style: const TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l.common_cancel,
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l.commitment_warning_confirm,
              style: const TextStyle(
                color: Color(0xFF1E5FFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navLockedToForever(BuildContext context) {
    context.go('/plans/forever');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectionOn = settings.protectionEnabled;
    final reelsShortsSelected = settings.socialMode == 'reelsAndShorts';
    final commitment = ref.watch(commitmentStatusProvider);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(activePlan: activePlan, streakDays: 3),
          const SizedBox(height: 12),

          // Master
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MasterToggleCard(
              title: l.dashboard_protection_title,
              activeLabel: l.dashboard_protection_active,
              offLabel: l.dashboard_protection_off,
              value: protectionOn,
              onChanged: (v) => _toggleMaster(context, ref, v),
            ),
          ),

          if (commitment.isActive) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CommitmentBanner(status: commitment, l: l),
            ),
          ],

          const SizedBox(height: 24),

          // Core
          _SectionWrapper(
            title: SectionTitle(title: l.dashboard_section_core),
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Opacity(
                    opacity: protectionOn ? 1.0 : 0.4,
                    child: Row(
                      children: [
                        Icon(
                          protectionOn
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          color: protectionOn
                              ? ProtectionDashboardScreen.green
                              : const Color(0xFF666666),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.dashboard_porn_websites_blocked,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.dashboard_porn_always_on,
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_search_filtering,
                value: settings.searchFilteringEnabled,
                onChanged: protectionOn
                    ? (v) => _toggle(ref, 'searchFilteringEnabled', v)
                    : null,
                parentEnabled: protectionOn,
                leadingIcon: Icons.search,
              ),
            ],
          ),

          // Social
          _SectionWrapper(
            title: SectionTitle(
              title: l.dashboard_section_social,
              comingSoonLabel: l.dashboard_coming_soon,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: PillSelector(
                  leftLabel: l.dashboard_social_mode_reels_shorts,
                  rightLabel: l.dashboard_social_mode_all,
                  isLeftSelected: reelsShortsSelected,
                  onSelectLeft: () => ref
                      .read(blockingSettingsActionsProvider.notifier)
                      .setSocialMode('reelsAndShorts'),
                  onSelectRight: () => ref
                      .read(blockingSettingsActionsProvider.notifier)
                      .setSocialMode('allSocial'),
                ),
              ),
              ToggleRow(
                label: l.dashboard_block_reels,
                value: settings.blockReels,
                onChanged: (v) => _toggle(ref, 'blockReels', v),
                isLocked: isFeatureLocked('blockReels', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.movie_outlined,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_shorts,
                value: settings.blockShorts,
                onChanged: (v) => _toggle(ref, 'blockShorts', v),
                isLocked: isFeatureLocked('blockShorts', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.smart_display_outlined,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_tiktok,
                value: settings.blockTikTok,
                onChanged: (v) => _toggle(ref, 'blockTikTok', v),
                isLocked: isFeatureLocked('blockTikTok', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.music_note,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_snapchat,
                value: settings.blockSnapchatStories,
                onChanged: (v) => _toggle(ref, 'blockSnapchatStories', v),
                isLocked:
                    isFeatureLocked('blockSnapchatStories', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.camera_alt_outlined,
              ),
            ],
          ),

          // Content
          _SectionWrapper(
            title: SectionTitle(
              title: l.dashboard_section_content,
              comingSoonLabel: l.dashboard_coming_soon,
            ),
            children: [
              ToggleRow(
                label: l.dashboard_block_shopping,
                value: settings.blockShopping,
                onChanged: (v) => _toggle(ref, 'blockShopping', v),
                isLocked: isFeatureLocked('blockShopping', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.shopping_bag_outlined,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_gambling,
                value: settings.blockGambling,
                onChanged: (v) => _toggle(ref, 'blockGambling', v),
                isLocked: isFeatureLocked('blockGambling', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.casino_outlined,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_image_search,
                value: settings.blockImageVideoSearch,
                onChanged: (v) => _toggle(ref, 'blockImageVideoSearch', v),
                isLocked:
                    isFeatureLocked('blockImageVideoSearch', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.image_search,
              ),
            ],
          ),

          // App control
          _SectionWrapper(
            title: SectionTitle(
              title: l.dashboard_section_app,
              comingSoonLabel: l.dashboard_coming_soon,
            ),
            children: [
              ToggleRow(
                label: l.dashboard_app_time_limits,
                value: settings.appTimeLimitsEnabled,
                onChanged: (v) => _toggle(ref, 'appTimeLimitsEnabled', v),
                isLocked:
                    isFeatureLocked('appTimeLimitsEnabled', activePlan),
                lockedTooltip: l.lock_monthly_plus,
                onLockedTap: () => context.go('/plans/monthly'),
                parentEnabled: protectionOn,
                leadingIcon: Icons.timer_outlined,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_custom_apps_blocklist,
                value: settings.customAppsBlocklistEnabled,
                onChanged: (v) =>
                    _toggle(ref, 'customAppsBlocklistEnabled', v),
                isLocked: isFeatureLocked(
                    'customAppsBlocklistEnabled', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.apps,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_block_in_app_browsers,
                value: settings.blockInAppBrowsers,
                onChanged: (v) => _toggle(ref, 'blockInAppBrowsers', v),
                isLocked: isFeatureLocked('blockInAppBrowsers', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.web,
              ),
            ],
          ),

          // Advanced
          _SectionWrapper(
            title: SectionTitle(
              title: l.dashboard_section_advanced,
              accentSubtitle: l.dashboard_advanced_subtitle,
            ),
            children: [
              ToggleRow(
                label: l.dashboard_prevent_uninstall,
                value: settings.preventUninstall,
                onChanged: (v) => _togglePreventUninstall(context, ref, v),
                isLocked: isFeatureLocked('preventUninstall', activePlan),
                lockedTooltip: l.lock_forever_only,
                onLockedTap: () => _navLockedToForever(context),
                parentEnabled: protectionOn,
                leadingIcon: Icons.lock_outline,
              ),
              const _RowSeparator(),
              ToggleRow(
                label: l.dashboard_accountability_partner,
                value: settings.accountabilityPartnerEnabled,
                onChanged: (v) =>
                    _toggle(ref, 'accountabilityPartnerEnabled', v),
                isLocked: false,
                parentEnabled: protectionOn,
                leadingIcon: Icons.people_outline,
              ),
            ],
          ),

          const SizedBox(height: 24),
          BigCtaButton(
            label: l.dashboard_cta_activate,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.dashboard_cta_saved),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF0A0F1C),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({required this.title, required this.children});
  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E1320),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A2238)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _CommitmentBanner extends StatelessWidget {
  const _CommitmentBanner({required this.status, required this.l});

  final CommitmentStatus status;
  final AppLocalizations l;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    final locked = status.isLocked;
    final permanent = status.isPermanent;
    final accent =
        locked ? const Color(0xFF1E5FFF) : ProtectionDashboardScreen.green;
    final String title;
    final String subtitle;
    if (permanent) {
      title = l.commitment_forever_banner;
      subtitle = l.commitment_forever_sub;
    } else if (locked) {
      title = l.commitment_locked_banner(status.daysLeft);
      subtitle = l.commitment_locked_sub(_shortDate(status.lockUntil!));
    } else {
      title = l.commitment_break_banner(status.minutesLeft);
      subtitle = l.commitment_break_sub;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1320),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
              permanent
                  ? Icons.lock
                  : locked
                      ? Icons.lock_clock
                      : Icons.self_improvement,
              color: accent,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowSeparator extends StatelessWidget {
  const _RowSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF1A2238),
    );
  }
}
