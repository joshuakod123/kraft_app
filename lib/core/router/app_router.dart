import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/streaming/stream_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(authProvider);

  return GoRouter(
    // [핵심] 초기 위치를 로그인 여부에 따라 결정
    initialLocation: isAuth ? '/home' : '/login',
    debugLogDiagnostics: true, // 디버그 로그 켜기

    redirect: (context, state) {
      final isLoggedIn = isAuth;
      final isGoingToLogin = state.uri.toString() == '/login';

      // 로그인 안했는데 로그인 화면이 아니면 -> 로그인으로
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      // 로그인 했는데 로그인 화면으로 가려하면 -> 홈으로
      if (isLoggedIn && isGoingToLogin) {
        return '/home';
      }
      return null; // 그 외에는 원래 가려던 곳으로
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/archive',
            builder: (context, state) => const CurriculumListScreen(),
          ),
          GoRoute(
            path: '/stream',
            builder: (context, state) => const StreamScreen(),
          ),
        ],
      ),
    ],
  );
});