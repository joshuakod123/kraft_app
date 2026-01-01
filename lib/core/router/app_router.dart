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
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/admin/qr_create_screen.dart';
import '../../features/attendance/attendance_scan_screen.dart';
import '../../features/attendance/attendance_list_screen.dart';
import '../../features/archive/archive_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/home/team_member_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<AuthStatus>(AuthStatus.initial);
  ref.listen<AuthStatus>(authProvider, (_, next) => authStateListenable.value = next);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStateListenable,
    redirect: (context, state) {
      final status = ref.read(authProvider);
      final goingTo = state.uri.toString();
      if (status == AuthStatus.initial && goingTo != '/splash') return '/splash';
      if (status == AuthStatus.unauthenticated && goingTo != '/login') return '/login';
      if (status == AuthStatus.onboardingRequired && goingTo != '/onboarding') return '/onboarding';
      if (status == AuthStatus.authenticated && (goingTo == '/splash' || goingTo == '/login')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // [임원진 기능] QR 생성 및 출석 명단
      GoRoute(path: '/qr_create', builder: (_, __) => const QrCreateScreen()),
      GoRoute(path: '/attendance_list', builder: (_, __) => const AttendanceListScreen()),

      GoRoute(path: '/attendance_scan', builder: (_, __) => const AttendanceScanScreen()),
      GoRoute(path: '/archive', builder: (_, __) => const ArchiveScreen()),
      GoRoute(path: '/assignment_upload', builder: (_, state) => AssignmentUploadScreen(item: state.extra as dynamic)),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: '/upcoming', pageBuilder: (_, __) => const NoTransitionPage(child: CurriculumListScreen())),
          GoRoute(path: '/team_members', pageBuilder: (_, __) => const NoTransitionPage(child: TeamMemberScreen())),

          // StreamScreen 호출 유지
          GoRoute(path: '/stream', pageBuilder: (_, __) => const NoTransitionPage(child: StreamScreen())),

          GoRoute(path: '/profile', pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
    ],
  );
});