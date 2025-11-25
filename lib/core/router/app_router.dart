import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/curriculum/assignment_upload_screen.dart'; // 추가
import '../../features/curriculum/curriculum_provider.dart'; // 추가 (CurriculumItem)
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/admin/qr_create_screen.dart'; // 추가
import '../../features/attendance/attendance_scan_screen.dart'; // 추가

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<bool>(ref.read(authProvider));

  ref.listen<bool>(authProvider, (previous, next) {
    authStateListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable,

    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider);
      final goingTo = state.uri.toString();

      if (goingTo == '/splash') return null;
      if (!isLoggedIn && goingTo != '/login') return '/login';
      if (isLoggedIn && goingTo == '/login') return '/home';

      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // [추가] QR 관련 (Shell 밖에서 전체 화면 사용)
      GoRoute(path: '/qr_create', builder: (context, state) => const QrCreateScreen()),
      GoRoute(path: '/attendance_scan', builder: (context, state) => const AttendanceScanScreen()),

      // [추가] 과제 업로드 (Shell 밖)
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