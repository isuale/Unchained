import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/dev_flags.dart';
import 'package:unchained/features/dashboard/data/feed_guard_bridge.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/domain/streak_progress.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
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

  /// Turning ON one of the Social feed blocks (Reels/Shorts/TikTok/Snapchat
  /// Stories) first asks how many minutes per day to allow before it's
  /// enforced — mirrors how a Family-Link-style app-timer prompts for a daily
  /// budget rather than just hard-blocking outright. Turning it off needs no
  /// prompt.
  Future<void> _toggleSocialFeed(
    BuildContext context,
    WidgetRef ref,
    String field,
    int currentLimit,
    bool value,
  ) async {
    final notifier = ref.read(blockingSettingsActionsProvider.notifier);
    bool applied;
    if (!value) {
      applied = await notifier.setSocialFeedTarget(field, false);
    } else {
      final minutes = await _askDailyLimitMinutes(context, currentLimit);
      if (minutes == null) return;
      applied = await notifier.setSocialFeedTarget(field, true, limitMinutes: minutes);
    }
    // Normally unreachable — the toggle row hides its Switch entirely while
    // locked — but guards the rare race where the lock lands between builds.
    if (!applied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.feed_guard_locked_refused),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0A0F1C),
        ),
      );
    }
  }

  /// Combines the plan-tier lock (`isFeatureLocked`) with the feed guard's
  /// own 24h exhaustion lock into a single [ToggleRow], since both use the
  /// same locked-look/tooltip/tap affordance but need different messaging.
  Widget _socialFeedToggleRow(
    BuildContext context,
    WidgetRef ref, {
    required String field,
    required String label,
    required IconData icon,
    required bool enabled,
    required int limitMinutes,
    required bool protectionOn,
    required bool planLocked,
    required DateTime? feedGuardLockedUntil,
  }) {
    return ToggleRow(
      label: label,
      sublabel: feedGuardLockedUntil != null
          ? l.feed_guard_locked_sublabel(_formatLockCountdown(feedGuardLockedUntil))
          : (enabled ? '$limitMinutes min/day' : null),
      value: enabled,
      onChanged: (v) => _toggleSocialFeed(context, ref, field, limitMinutes, v),
      isLocked: planLocked || feedGuardLockedUntil != null,
      lockedTooltip:
          planLocked ? l.lock_forever_only : l.feed_guard_locked_tooltip,
      onLockedTap: planLocked
          ? () => _navLockedToForever(context)
          : () => _showFeedGuardLockedMessage(context, feedGuardLockedUntil!),
      parentEnabled: protectionOn,
      leadingIcon: icon,
      // Dev-only: long-press resets this target's daily budget + 24h lock.
      // Compiled out entirely in normal builds (kDevTools == false).
      onLongPress:
          kDevTools ? () => _confirmResetFeedGuard(context, ref, field, label) : null,
    );
  }

  /// Dev-only (DEV_TOOLS) hard reset of one feed-guard target: clears today's
  /// usage and drops the 24h exhaustion lock so the budget is fresh again,
  /// bypassing the anti-circumvention cooldown for testing.
  Future<void> _confirmResetFeedGuard(
    BuildContext context,
    WidgetRef ref,
    String field,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E18),
        title: const Text(
          'Reset daily budget?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'DEV: clears today\'s usage and the 24h lock for "$label" so it\'s '
          'usable again immediately. Past-day history is kept.',
          style: const TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFF1E5FFF))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await FeedGuardBridge.resetTarget(field);
    // Force an immediate refresh (the provider also re-polls every second).
    ref.invalidate(feedGuardStatusesProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '$label budget reset' : 'Reset failed'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A0F1C),
      ),
    );
  }

  void _showFeedGuardLockedMessage(BuildContext context, DateTime lockedUntil) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(l.feed_guard_locked_message(_formatLockCountdown(lockedUntil))),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A0F1C),
      ),
    );
  }

  /// "3h 12m" / "12m" remaining until [lockedUntil], for the countdown shown
  /// on a locked feed-guard row.
  String _formatLockCountdown(DateTime lockedUntil) {
    final remaining = lockedUntil.difference(DateTime.now());
    if (remaining.isNegative) return '0m';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Simple stepper dialog for "how many minutes per day?" (1-180, steps of 5
  /// except down to the 1-minute floor, which exists for fast manual testing).
  Future<int?> _askDailyLimitMinutes(BuildContext context, int initial) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var minutes = initial.clamp(1, 180);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF0A0E18),
            title: const Text(
              'Minutes per day',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Allowed today before it gets blocked for the rest of the day.',
                  style: TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: minutes > 1
                          ? () => setState(
                              () => minutes = (minutes - 5).clamp(1, 180))
                          : null,
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFF1E5FFF)),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '$minutes',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: minutes < 180
                          ? () => setState(() => minutes += 5)
                          : null,
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF1E5FFF)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF888888))),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(minutes),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                      color: Color(0xFF1E5FFF), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final feedGuardStatuses =
        ref.watch(feedGuardStatusesProvider).asData?.value ?? const {};

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardHeader(
            activePlan: activePlan,
            streakDays: currentStreakDays(
                settings.protectionStartedAt, DateTime.now()),
          ),
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
            title: SectionTitle(title: l.dashboard_section_social),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _FeedGuardPermissionBanner(),
              ),
              _socialFeedToggleRow(
                context,
                ref,
                field: 'blockReels',
                label: l.dashboard_block_reels,
                icon: Icons.movie_outlined,
                enabled: settings.blockReels,
                limitMinutes: settings.reelsLimitMinutes,
                protectionOn: protectionOn,
                planLocked: isFeatureLocked('blockReels', activePlan),
                feedGuardLockedUntil: feedGuardStatuses['blockReels']?.lockedUntil,
              ),
              const _RowSeparator(),
              _socialFeedToggleRow(
                context,
                ref,
                field: 'blockShorts',
                label: l.dashboard_block_shorts,
                icon: Icons.smart_display_outlined,
                enabled: settings.blockShorts,
                limitMinutes: settings.shortsLimitMinutes,
                protectionOn: protectionOn,
                planLocked: isFeatureLocked('blockShorts', activePlan),
                feedGuardLockedUntil: feedGuardStatuses['blockShorts']?.lockedUntil,
              ),
              const _RowSeparator(),
              _socialFeedToggleRow(
                context,
                ref,
                field: 'blockTikTok',
                label: l.dashboard_block_tiktok,
                icon: Icons.music_note,
                enabled: settings.blockTikTok,
                limitMinutes: settings.tiktokLimitMinutes,
                protectionOn: protectionOn,
                planLocked: isFeatureLocked('blockTikTok', activePlan),
                feedGuardLockedUntil: feedGuardStatuses['blockTikTok']?.lockedUntil,
              ),
              const _RowSeparator(),
              _socialFeedToggleRow(
                context,
                ref,
                field: 'blockSnapchatStories',
                label: l.dashboard_block_snapchat,
                icon: Icons.camera_alt_outlined,
                enabled: settings.blockSnapchatStories,
                limitMinutes: settings.snapchatLimitMinutes,
                protectionOn: protectionOn,
                planLocked: isFeatureLocked('blockSnapchatStories', activePlan),
                feedGuardLockedUntil:
                    feedGuardStatuses['blockSnapchatStories']?.lockedUntil,
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

/// Enforcing the Social feed limits requires a dedicated accessibility
/// service (it has to watch for the Reels/Shorts/TikTok/Snapchat screens the
/// same way the uninstall watchdog watches for Settings). Toggling a feed on
/// above silently does nothing until this is granted, so surface it inline
/// rather than leaving that a mystery.
class _FeedGuardPermissionBanner extends StatefulWidget {
  const _FeedGuardPermissionBanner();

  @override
  State<_FeedGuardPermissionBanner> createState() =>
      _FeedGuardPermissionBannerState();
}

class _FeedGuardPermissionBannerState
    extends State<_FeedGuardPermissionBanner> with WidgetsBindingObserver {
  bool _loading = true;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await FeedGuardBridge.isAccessibilityEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _enabled) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFB800), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enable Accessibility access to enforce these daily limits.',
              style: TextStyle(color: Color(0xFFB8C0D0), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FeedGuardBridge.openAccessibilitySettings();
            },
            child: const Text('Enable',
                style: TextStyle(color: Color(0xFF1E5FFF))),
          ),
        ],
      ),
    );
  }
}
