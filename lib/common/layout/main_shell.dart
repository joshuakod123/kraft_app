import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart'; // PlayerState 사용을 위해 추가

import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/streaming/audio_service.dart'; // 오디오 서비스 추가
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRedirectIfNeeded());
  }

  Future<void> _checkAndRedirectIfNeeded() async {
    final authStatus = ref.read(authProvider);
    if (authStatus != AuthStatus.authenticated) return;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) { if (next == AuthStatus.authenticated) _checkAndRedirectIfNeeded(); });

    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);
    final currentSong = ref.watch(currentSongProvider);
    final isExpanded = ref.watch(isPlayerExpandedProvider);

    return PopScope(
      canPop: !isExpanded,
      onPopInvoked: (didPop) { if (!didPop && isExpanded) ref.read(isPlayerExpandedProvider.notifier).state = false; },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(bottom: 80, child: widget.child),
            Positioned(
              left: 0, right: 0, bottom: 0, height: 80,
              child: _buildNavBar(currentIndex),
            ),

            // [수정] currentSong이 있을 때만 플레이어 표시 & song 데이터 전달
            if (currentSong != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: isExpanded ? 0 : null,
                bottom: isExpanded ? 0 : 80, // 탭바 높이만큼 띄움
                left: 0, right: 0,
                height: isExpanded ? null : 64, // 미니 플레이어 높이
                child: GestureDetector(
                  onTap: () { if (!isExpanded) ref.read(isPlayerExpandedProvider.notifier).state = true; },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    // [수정] StreamScreen과 _MiniPlayer에 song 전달
                    child: isExpanded
                        ? StreamScreen(song: currentSong)
                        : _MiniPlayer(song: currentSong),
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

  Widget _buildNavBar(int currentIndex) {
    return Container(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarIcon(icon: Icons.home, index: 0, currentIndex: currentIndex, path: '/home'),
          _NavBarIcon(icon: Icons.calendar_today, index: 1, currentIndex: currentIndex, path: '/upcoming'),
          _NavBarIcon(icon: Icons.people, index: 2, currentIndex: currentIndex, path: '/team_members'),
          _NavBarIcon(icon: Icons.play_circle_outline, index: 3, currentIndex: currentIndex, path: '/stream'),
          _NavBarIcon(icon: Icons.person, index: 4, currentIndex: currentIndex, path: '/profile'),
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
  const _NavBarIcon({required this.icon, required this.index, required this.currentIndex, required this.path});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          if (ref.read(currentSongProvider) != null) {
            ref.read(isPlayerExpandedProvider.notifier).state = true;
          } else {
            context.go(path);
          }
          return;
        }
        context.go(path);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
      ),
    );
  }
}

// [추가] 미니 플레이어 위젯을 파일 내부에 정의 (파일 삭제 대응)
class _MiniPlayer extends StatelessWidget {
  final MediaItem song;
  const _MiniPlayer({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 앨범 커버
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[800],
              image: song.artUri != null
                  ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                  : null,
            ),
            child: song.artUri == null ? const Icon(Icons.music_note, size: 20, color: Colors.white54) : null,
          ),
          const SizedBox(width: 12),
          // 제목 & 가수
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(song.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // 재생/일시정지 버튼
          StreamBuilder<PlayerState>(
            stream: KraftAudioService.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: playing ? KraftAudioService.pause : KraftAudioService.resume,
              );
            },
          ),
        ],
      ),
    );
  }
}