import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/dashboard_screen.dart';
import 'package:unchained/features/guard/presentation/scripture_lock_screen.dart';
import 'package:unchained/features/dashboard/stubs/accountability_stub.dart';
import 'package:unchained/features/legal/presentation/terms_screen.dart';
import 'package:unchained/features/onboarding/presentation/analyzing_screen.dart';
import 'package:unchained/features/onboarding/presentation/onboarding_screen.dart';
import 'package:unchained/features/plans/presentation/ai_plan_screen.dart';
import 'package:unchained/features/plans/presentation/all_plans_screen.dart';
import 'package:unchained/features/plans/presentation/forever_plan_screen.dart';
import 'package:unchained/features/plans/presentation/free_trial_plan_screen.dart';
import 'package:unchained/features/plans/presentation/monthly_plan_screen.dart';
import 'package:unchained/features/plans/presentation/monthly_setup_screen.dart';
import 'package:unchained/features/prayer/presentation/app_picker_screen.dart';
import 'package:unchained/features/prayer/presentation/prayer_gate_screen.dart';
import 'package:unchained/features/splash/presentation/splash_screen.dart';
import 'package:unchained/features/welcome/presentation/welcome_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/analyzing',
      builder: (context, state) => const AnalyzingScreen(),
    ),
    GoRoute(
      path: '/plans/ai',
      builder: (context, state) => const AiPlanScreen(),
    ),
    GoRoute(
      path: '/plans/free-trial',
      builder: (context, state) => const FreeTrialPlanScreen(),
    ),
    GoRoute(
      path: '/plans/monthly',
      builder: (context, state) => const MonthlyPlanScreen(),
    ),
    GoRoute(
      path: '/plans/monthly/setup',
      builder: (context, state) => const MonthlySetupScreen(),
    ),
    GoRoute(
      path: '/plans/forever',
      builder: (context, state) => const ForeverPlanScreen(),
    ),
    GoRoute(
      path: '/plans/all',
      builder: (context, state) => const AllPlansScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => TermsScreen(
        isGate: state.extra is bool ? state.extra as bool : true,
      ),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => DashboardScreen(
        initialTab: state.extra is int ? state.extra as int : 0,
      ),
    ),
    GoRoute(
      path: '/accountability',
      builder: (context, state) => const AccountabilityStub(),
    ),
    GoRoute(
      path: '/apps',
      builder: (context, state) => const AppPickerScreen(),
    ),
    GoRoute(
      path: '/pray',
      builder: (context, state) => PrayerGateScreen(
        args: state.extra is PrayerGateArgs
            ? state.extra as PrayerGateArgs
            : const PrayerGateArgs(),
      ),
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) => ScriptureLockScreen(
        mode: state.extra is LockMode ? state.extra as LockMode : LockMode.block,
      ),
    ),
  ],
);
