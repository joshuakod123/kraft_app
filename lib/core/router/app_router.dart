import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/curriculum/assignment_upload_screen.dart';
import '../../features/curriculum/curriculum_provider.dart';
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/admin/qr_create_screen.dart';
import '../../features/attendance/attendance_scan_screen.dart';
import '../../features/archive/archive_screen.dart';
import '../../features/profile/profile_screen.dart';
// [삭제됨] 커뮤니티 스크린 import 제거
import '../../features/home/team_member_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<AuthStatus>(AuthStatus.initial);

  ref.listen<AuthStatus>(authProvider, (_, next) {
    authStateListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable,

    redirect: (context, state) {
      final status = ref.read(authProvider);
      final goingTo = state.uri.toString();

      if (status == AuthStatus.initial) {
        if (goingTo != '/splash') return '/splash';
        return null;
      }
      if (status == AuthStatus.unauthenticated) {
        if (goingTo != '/login') return '/login';
        return null;
      }
      if (status == AuthStatus.onboardingRequired) {
        if (goingTo != '/onboarding') return '/onboarding';
        return null;
      }
      if (status == AuthStatus.authenticated) {
        if (goingTo == '/splash' || goingTo == '/login' || goingTo == '/onboarding') {
          return '/home';
        }
      }
      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/qr_create', builder: (context, state) => const QrCreateScreen()),
      GoRoute(path: '/attendance_scan', builder: (context, state) => const AttendanceScanScreen()),
      GoRoute(
        path: '/assignment_upload',
        builder: (context, state) {
          final item = state.extra as CalendarEvent;
          return AssignmentUploadScreen(item: item);
        },
      ),
      GoRoute(path: '/archive', builder: (context, state) => const ArchiveScreen()),

      // [Main Shell]
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (context, state) => NoTransitionPage(child: const HomeScreen())),
          GoRoute(path: '/upcoming', pageBuilder: (context, state) => NoTransitionPage(child: const CurriculumListScreen())),

          GoRoute(path: '/team_members', pageBuilder: (context, state) => NoTransitionPage(child: const TeamMemberScreen())),

          // [삭제됨] /community 관련 라우트 전체 제거

          GoRoute(path: '/stream', pageBuilder: (context, state) => NoTransitionPage(child: const StreamScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => NoTransitionPage(child: const ProfileScreen())),
        ],
      ),
    ],
  );
});