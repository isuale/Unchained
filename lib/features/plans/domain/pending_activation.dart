import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';

/// The plan+schedule the user was trying to buy, captured right before they're
/// sent to Stripe checkout and persisted to disk (see [BlockingSettingsRepository
/// .setPendingActivation]) so it survives the app being backgrounded — or even
/// killed by Android — while the browser is open. Read back once payment is
/// confirmed via the `unchained://paid` deep link, then applied and cleared.
@immutable
class PendingActivation {
  const PendingActivation({
    required this.planId,
    required this.plan,
    required this.schedule,
    required this.email,
  });

  /// The id used with Stripe/the backend: 'monthly' | 'ai_plan' | 'forever'.
  final String planId;
  final ActivePlan plan;
  final CommitmentSchedule schedule;
  final String email;

  String toJson() => jsonEncode({
        'planId': planId,
        'plan': plan.name,
        'commitmentMode': commitmentModeToString(schedule.mode),
        'totalDays': schedule.totalDays,
        'breakCount': schedule.breakCount,
        'email': email,
      });

  static PendingActivation? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PendingActivation(
        planId: map['planId'] as String,
        plan: activePlanFromString(map['plan'] as String) ??
            ActivePlan.freeTrial,
        schedule: CommitmentSchedule(
          mode: commitmentModeFromString(map['commitmentMode'] as String?),
          totalDays: map['totalDays'] as int? ?? 0,
          breakCount: map['breakCount'] as int? ?? 0,
        ),
        email: map['email'] as String? ?? '',
      );
    } catch (_) {
      // Corrupt/unrecognized JSON — treat as if nothing was pending rather
      // than crash the app trying to resume a payment.
      return null;
    }
  }
}
