import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart'; // 추가
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/curriculum/assignment_upload_screen.dart';
import '../../features/curriculum/curriculum_provider.dart';
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/admin/qr_create_screen.dart';
import '../../features/attendance/attendance_scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatusListenable = ValueNotifier<AuthStatus>(ref.read(authProvider));

  ref.listen<AuthStatus>(authProvider, (previous, next) {
    authStatusListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStatusListenable,

    redirect: (context, state) {
      final status = ref.read(authProvider);
      final goingTo = state.uri.toString();

      if (goingTo == '/splash') return null; // 스플래시는 내부 타이머로 이동

      // 1. 로그인 안됨
      if (status == AuthStatus.unauthenticated) {
        if (goingTo != '/login') return '/login';
      }

      // 2. 온보딩 필요 (로그인은 됐으나 정보 없음)
      if (status == AuthStatus.onboardingRequired) {
        if (goingTo != '/onboarding') return '/onboarding';
      }

      // 3. 로그인 완료됨
      if (status == AuthStatus.authenticated) {
        if (goingTo == '/login' || goingTo == '/onboarding' || goingTo == '/splash') {
          return '/home';
        }
      }

      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()), // 추가

      GoRoute(path: '/qr_create', builder: (context, state) => const QrCreateScreen()),
      GoRoute(path: '/attendance_scan', builder: (context, state) => const AttendanceScanScreen()),

      GoRoute(
        path: '/assignment_upload',
        builder: (context, state) {
          final item = state.extra as CurriculumItem;
          return AssignmentUploadScreen(item: item);
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/archive', builder: (context, state) => const CurriculumListScreen()),
          GoRoute(path: '/stream', builder: (context, state) => const StreamScreen()),
        ],
      ),
    ],
  );
});