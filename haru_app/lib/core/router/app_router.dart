import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/shell/main_shell.dart';
import '../../features/journal/journal_list_screen.dart';
import '../../features/journal/journal_write_screen.dart';
import '../../features/journal/journal_detail_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/coach/coach_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/subscription/pro_screen.dart';
import '../../features/report/weekly_report_screen.dart';
import '../../features/report/weekly_emotion_report_screen.dart';
import '../../features/journal/emotion_stats_screen.dart';
import '../../features/legal/help_faq_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/places/places_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  // OAuth 콜백 딥링크(io.supabase.harugyeol://...)는 GoRouter가 라우트를
  // 찾지 못하므로, onException에서 auth-gate로 보내면 supabase_flutter가
  // 이미 코드 교환을 마친 상태라 자동으로 /home으로 이동합니다.
  onException: (context, state, router) {
    final scheme = state.uri.scheme;
    if (scheme == 'io.supabase.harugyeol') {
      router.go('/auth-gate');
    } else {
      router.go('/login');
    }
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    // OAuth 콜백 처리 (Supabase 딥링크)
    GoRoute(path: '/auth-gate', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main shell with bottom nav
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: JournalListScreen()),
        ),
        GoRoute(
          path: '/habits',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HabitsScreen()),
        ),
        GoRoute(
          path: '/coach',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CoachScreen()),
        ),
        GoRoute(
          path: '/places',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PlacesScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/journal/write',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          child: JournalWriteScreen(
            journalId: extra?['journalId'] as String?,
            initialContent: extra?['initialContent'] as String?,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/journal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          JournalDetailScreen(journalId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/pro',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ProScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WeeklyReportScreen(),
    ),
    GoRoute(
      path: '/emotion-stats',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EmotionStatsScreen(),
    ),
    GoRoute(
      path: '/weekly-emotion-report',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const WeeklyEmotionReportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/help-faq',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HelpFaqScreen(),
    ),
  ],
);
