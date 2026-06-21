import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/dashboard_screen.dart';
import 'package:unchained/features/dashboard/stubs/accountability_stub.dart';
import 'package:unchained/features/onboarding/presentation/analyzing_screen.dart';
import 'package:unchained/features/onboarding/presentation/onboarding_screen.dart';
import 'package:unchained/features/plans/presentation/ai_plan_screen.dart';
import 'package:unchained/features/plans/presentation/all_plans_screen.dart';
import 'package:unchained/features/plans/presentation/forever_plan_screen.dart';
import 'package:unchained/features/plans/presentation/free_trial_plan_screen.dart';
import 'package:unchained/features/plans/presentation/monthly_plan_screen.dart';
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
      path: '/plans/forever',
      builder: (context, state) => const ForeverPlanScreen(),
    ),
    GoRoute(
      path: '/plans/all',
      builder: (context, state) => const AllPlansScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/accountability',
      builder: (context, state) => const AccountabilityStub(),
    ),
  ],
);
