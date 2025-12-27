import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart'; // Repository
import '../../core/state/global_providers.dart';
import '../../features/auth/auth_provider.dart'; // AuthProvider
import '../../features/streaming/mini_player.dart';
import '../../features/streaming/player_provider.dart';
import '../../features/streaming/stream_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // [New] 앱 실행/재실행 시 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRedirectIfNeeded();
    });
  }

  // [New] 임시 비밀번호 상태 감지 및 자동 리다이렉트
  Future<void> _checkAndRedirectIfNeeded() async {
    // 1. 로그인 상태 확인
    final authStatus = ref.read(authProvider);
    if (authStatus != AuthStatus.authenticated) return;

    // 2. 프로필 정보 가져오기
    final profile = await SupabaseRepository().getUserProfile();

    // 3. 임시 비밀번호라면 프로필 페이지로 이동
    if (profile != null && profile['is_temp_password'] == true) {
      if (!mounted) return;
      // 현재 위치가 이미 profile이 아니라면 이동
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith('/profile')) {
        context.go('/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // [New] Auth 상태가 변할 때마다 체크 (로그인 직후 등)
    ref.listen(authProvider, (previous, next) {
      if (next == AuthStatus.authenticated) {
        _checkAndRedirectIfNeeded();
      }
    });

    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    const double navBarHeight = 80.0;
    const double miniPlayerHeight = 68.0;
    const double miniPlayerMargin = 12.0;

    return PopScope(
      canPop: !isExpanded,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isExpanded) {
          ref.read(isPlayerExpandedProvider.notifier).state = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              bottom: navBarHeight,
              child: widget.child,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: navBarHeight,
              child: _buildGlassNavBar(context, currentIndex),
            ),
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                top: isExpanded ? 0 : MediaQuery.of(context).size.height - navBarHeight - miniPlayerHeight - miniPlayerMargin,
                bottom: isExpanded ? 0 : navBarHeight + miniPlayerMargin,
                left: isExpanded ? 0 : miniPlayerMargin,
                right: isExpanded ? 0 : miniPlayerMargin,
                child: GestureDetector(
                  onTap: () {
                    if (!isExpanded) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (isExpanded && details.primaryVelocity! > 500) {
                      ref.read(isPlayerExpandedProvider.notifier).state = false;
                    } else if (!isExpanded && details.primaryVelocity! < -500) {
                      ref.read(isPlayerExpandedProvider.notifier).state = true;
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: isExpanded ? BorderRadius.zero : BorderRadius.circular(12),
                      boxShadow: [
                        if (!isExpanded)
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isExpanded
                          ? StreamScreen(mediaItem: currentSong)
                          : MiniPlayer(song: currentSong),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/upcoming')) return 1;
    if (location.startsWith('/team_members')) return 2;
    if (location.startsWith('/stream')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  Widget _buildGlassNavBar(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarIcon(icon: Icons.home_rounded, index: 0, currentIndex: currentIndex, path: '/home'),
          _NavBarIcon(icon: Icons.calendar_month_rounded, index: 1, currentIndex: currentIndex, path: '/upcoming'),
          _NavBarIcon(icon: Icons.groups_3_rounded, index: 2, currentIndex: currentIndex, path: '/team_members'),
          _NavBarIcon(icon: Icons.play_circle_outline_rounded, index: 3, currentIndex: currentIndex, path: '/stream'),
          _NavBarIcon(icon: Icons.person_outline_rounded, index: 4, currentIndex: currentIndex, path: '/profile'),
        ],
      ),
    );
  }
}

class _NavBarIcon extends ConsumerWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final String path;

  const _NavBarIcon({super.key, required this.icon, required this.index, required this.currentIndex, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          final currentSong = ref.read(currentSongProvider);
          if (currentSong != null) {
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          } else {
            context.go(path);
          }
          return;
        }
        context.go(path);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Icon(icon, color: isSelected ? dept.color : Colors.grey, size: 28)
            .animate(target: isSelected ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),
      ),
    );
  }
}