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

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<AuthStatus>(AuthStatus.initial);

  ref.listen<AuthStatus>(authProvider, (previous, next) {
    authStateListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable,

    redirect: (context, state) {
      final status = ref.read(authProvider);
      final goingTo = state.uri.toString();

      // 1. 로딩 중 -> 스플래시 유지
      if (status == AuthStatus.initial) return '/splash';

      // 2. 로그인 안 됨 -> 로그인 화면으로
      if (status == AuthStatus.unauthenticated) {
        if (goingTo != '/login') return '/login';
      }

      // 3. 로그인 됐으나 정보 없음 -> 온보딩으로
      if (status == AuthStatus.onboardingRequired) {
        if (goingTo != '/onboarding') return '/onboarding';
      }

      // 4. 로그인 & 정보 있음 -> 홈으로 (로그인/온보딩/스플래시 접근 시)
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
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()), // 추가됨

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