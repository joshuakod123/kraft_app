import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/layout/main_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/curriculum/curriculum_list_screen.dart';
import '../../features/streaming/stream_screen.dart';
import '../../features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    refreshListenable: GoRouterRefreshStream(authNotifier.stream),

    redirect: (context, state) {
      // [수정] 리다이렉트 시점의 최신 상태 확인
      final isLoggedIn = ref.read(authProvider);
      final goingTo = state.uri.toString();

      // 1. 스플래시 화면은 통과
      if (goingTo == '/splash') return null;

      // 2. 로그인 안 함 -> 로그인 화면으로 (로그인 화면이 아니면)
      if (!isLoggedIn && goingTo != '/login') return '/login';

      // 3. 로그인 함 -> 홈으로 (로그인 화면이나 스플래시라면)
      if (isLoggedIn && (goingTo == '/login' || goingTo == '/splash')) return '/home';

      return null; // 그 외에는 원래 가려던 곳으로 이동
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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

// [유틸리티 클래스] Riverpod 상태 변화를 GoRouter가 감지할 수 있게 변환
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
          (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}