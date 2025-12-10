// (Imports 부분 생략 - 위와 동일)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/curriculum/assignment_upload_screen.dart';
import '../../features/curriculum/curriculum_provider.dart';
import '../../features/streaming/stream_screen.dart';
import '../../features/streaming/player_provider.dart'; // [추가] Provider 필요
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
    // (redirect 로직은 그대로 유지)
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

      GoRoute(
        path: '/assignment_upload',
        builder: (context, state) {
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

          // [핵심 수정] 탭 클릭 시 현재 재생 중인 노래 유지
          GoRoute(
              path: '/stream',
              pageBuilder: (context, state) {
                MediaItem mediaItem;
                // 1. 다른 화면에서 넘겨준 곡이 있으면 그걸 씀
                if (state.extra is MediaItem) {
                  mediaItem = state.extra as MediaItem;
                } else {
                  // 2. 없으면(탭 클릭 시) 현재 재생 중인 곡을 가져옴
                  final currentSong = ref.read(currentSongProvider);
                  if (currentSong != null) {
                    mediaItem = currentSong;
                  } else {
                    // 3. 재생 중인 것도 없으면 더미 데이터 or 빈 상태
                    mediaItem = const MediaItem(id: '0', title: '재생 중인 곡 없음', artist: 'KRAFT Music');
                  }
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