import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_provider.dart';
import 'audio_service.dart';
import 'stream_screen.dart'; // [중요] 화면 이동을 위해 꼭 필요합니다.

class MiniPlayer extends ConsumerWidget {
  // 생성자에서 매개변수(song)를 제거했습니다.
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 전역 상태에서 곡 정보를 가져옵니다.
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      // 탭하면 상세 화면으로 이동
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StreamScreen()),
      ),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // 배경색 추가
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            // 앨범 아트
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.artUri != null
                  ? Image.network(song.artUri.toString(), width: 48, height: 48, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], width: 48, height: 48, child: const Icon(Icons.music_note, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            // 제목 및 아티스트
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(song.artist ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // 재생/일시정지 버튼
            StreamBuilder(
              stream: KraftAudioService.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return IconButton(
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  onPressed: isPlaying ? KraftAudioService.pause : KraftAudioService.resume,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}