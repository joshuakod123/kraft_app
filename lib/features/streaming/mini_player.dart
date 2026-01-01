import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'player_provider.dart';
import 'audio_service.dart';
import 'stream_screen.dart';

class MiniPlayer extends ConsumerWidget {
  // [수정] 매개변수 삭제! const MiniPlayer({super.key});
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // [수정] 인자값 없이 화면 이동
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StreamScreen()));
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.artUri != null
                  ? Image.network(song.artUri.toString(), width: 45, height: 45, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], width: 45, height: 45),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                  Text(song.artist ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1),
                ],
              ),
            ),
            StreamBuilder(
              stream: KraftAudioService.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return IconButton(
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: isPlaying ? KraftAudioService.pause : KraftAudioService.resume,
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}