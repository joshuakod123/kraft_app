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
import '../../features/archive/archive_screen.dart'; // [신규]
import '../../features/profile/profile_screen.dart'; // [신규]

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

      // [Fade Effect] 로그인 화면
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
          final item = state.extra as CurriculumItem;
          return AssignmentUploadScreen(item: item);
        },
      ),

      // [메인 쉘 - 5개 탭]
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // 1. Home
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(child: const HomeScreen()),
          ),
          // 2. Upcoming (기존 Curriculum 화면)
          GoRoute(
            path: '/upcoming',
            pageBuilder: (context, state) => NoTransitionPage(child: const CurriculumListScreen()),
          ),
          // 3. Archive (내가 올린 파일 목록)
          GoRoute(
            path: '/archive',
            pageBuilder: (context, state) => NoTransitionPage(child: const ArchiveScreen()),
          ),
          // 4. Streaming
          GoRoute(
            path: '/stream',
            pageBuilder: (context, state) => NoTransitionPage(child: const StreamScreen()),
          ),
          // 5. Profile
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(child: const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});