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
import '../../features/community/community_screen.dart';

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

          // [수정] Community 경로 하위에 Detail 경로 추가 (이동 문제 해결)
          GoRoute(
            path: '/community',
            pageBuilder: (context, state) => NoTransitionPage(child: const CommunityScreen()),
            routes: [
              GoRoute(
                path: 'detail', // 실제 경로: /community/detail
                builder: (context, state) {
                  final post = state.extra as Map<String, dynamic>;
                  // PostDetailScreen은 CommunityScreen 파일 안에 정의되어 있습니다.
                  // 이 코드가 작동하려면 CommunityScreen 파일에서 PostDetailScreen을 public으로 바꾸거나
                  // 같은 파일에 있어야 하는데, router 파일에서는 PostDetailScreen 클래스를 직접 참조하기 어렵습니다.
                  // 해결책: CommunityScreen.dart 파일에서 'PostDetailScreen' 클래스를 찾아서
                  // '_PostDetailScreen' (언더바 제거)으로 이름을 바꾸고 public 클래스로 만들어야 합니다.
                  // 하지만 편의를 위해 아래 CommunityScreen 수정 코드에 'PostDetailScreen'을 별도 클래스로 분리해 드리겠습니다.
                  return PostDetailScreen(post: post);
                },
              ),
            ],
          ),

          GoRoute(path: '/stream', pageBuilder: (context, state) => NoTransitionPage(child: const StreamScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => NoTransitionPage(child: const ProfileScreen())),
        ],
      ),
    ],
  );
});