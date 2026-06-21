import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';

enum ActivePlan { freeTrial, monthly, aiPlan, forever }

ActivePlan? activePlanFromString(String? s) => switch (s) {
      'freeTrial' => ActivePlan.freeTrial,
      'monthly' => ActivePlan.monthly,
      'aiPlan' => ActivePlan.aiPlan,
      'forever' => ActivePlan.forever,
      _ => null,
    };

final activePlanProvider = Provider<ActivePlan?>((ref) {
  final settings = ref.watch(blockingSettingsProvider);
  return settings.maybeWhen(
    data: (s) => activePlanFromString(s.activePlan),
    orElse: () => null,
  );
});

class ActivePlanActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> setActivePlan(ActivePlan plan) {
    return ref
        .read(blockingSettingsRepositoryProvider)
        .setActivePlan(plan.name);
  }
}

final activePlanActionsProvider =
    NotifierProvider<ActivePlanActions, void>(ActivePlanActions.new);

bool isFeatureLocked(String featureKey, ActivePlan? plan) {
  if (plan == null) return true;

  const alwaysUnlocked = {
    'searchFilteringEnabled',
    'accountabilityPartnerEnabled',
  };
  if (alwaysUnlocked.contains(featureKey)) return false;

  switch (plan) {
    case ActivePlan.freeTrial:
      return true;
    case ActivePlan.monthly:
    case ActivePlan.aiPlan:
      return featureKey != 'appTimeLimitsEnabled';
    case ActivePlan.forever:
      return false;
  }
}
