import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart'; // MediaItem

import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/curriculum/assignment_upload_screen.dart';
import '../../features/curriculum/curriculum_provider.dart'; // [중요] CalendarEvent가 정의된 파일 import
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/admin/qr_create_screen.dart';
import '../../features/attendance/attendance_scan_screen.dart';
import '../../features/archive/archive_screen.dart';
import '../../features/profile/profile_screen.dart';
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

      if (status == AuthStatus.initial && goingTo != '/splash') return '/splash';
      if (status == AuthStatus.unauthenticated && goingTo != '/login') return '/login';
      if (status == AuthStatus.onboardingRequired && goingTo != '/onboarding') return '/onboarding';
      if (status == AuthStatus.authenticated &&
          (goingTo == '/splash' || goingTo == '/login' || goingTo == '/onboarding')) {
        return '/home';
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

      // [수정 완료] assignment_upload 라우트 에러 해결
      GoRoute(
        path: '/assignment_upload',
        builder: (context, state) {
          // state.extra는 Object? 타입이므로 as CalendarEvent로 형변환이 필요합니다.
          // 만약 extra가 null이거나 다른 타입이면 에러가 날 수 있으니 주의해야 하지만,
          // 로직상 항상 CalendarEvent를 넘겨준다고 가정합니다.
          final item = state.extra as CalendarEvent;
          return AssignmentUploadScreen(item: item);
        },
      ),

      GoRoute(path: '/archive', builder: (context, state) => const ArchiveScreen()),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (context, state) => NoTransitionPage(child: const HomeScreen())),
          GoRoute(path: '/upcoming', pageBuilder: (context, state) => NoTransitionPage(child: const CurriculumListScreen())),
          GoRoute(path: '/team_members', pageBuilder: (context, state) => NoTransitionPage(child: const TeamMemberScreen())),

          // StreamScreen 연결
          GoRoute(
              path: '/stream',
              pageBuilder: (context, state) {
                // 안전하게 MediaItem으로 캐스팅 (데이터가 없으면 더미 데이터 사용)
                MediaItem mediaItem;
                if (state.extra is MediaItem) {
                  mediaItem = state.extra as MediaItem;
                } else {
                  mediaItem = const MediaItem(id: '0', title: 'Unknown Track', artist: 'Unknown Artist');
                }
                return NoTransitionPage(child: StreamScreen(mediaItem: mediaItem));
              }
          ),

          GoRoute(path: '/profile', pageBuilder: (context, state) => NoTransitionPage(child: const ProfileScreen())),
        ],
      ),
    ],
  );
});