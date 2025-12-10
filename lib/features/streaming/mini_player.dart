import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../common/widgets/glass_card.dart';

class MiniPlayer extends StatelessWidget {
  final MediaItem song;

  const MiniPlayer({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    // 여기서는 클릭 이벤트를 처리하지 않습니다. (MainShell에서 처리)
    return GlassCard(
      opacity: 0.95,
      child: Container(
        height: 68, // 높이 고정
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. 앨범 아트
            Hero(
              tag: 'albumArt_${song.id}',
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: song.artUri != null
                      ? DecorationImage(image: NetworkImage(song.artUri.toString()), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. 곡 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      song.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  Text(
                      song.artist ?? '',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),

            // 3. 아이콘 (디자인 요소)
            // 실제 기능은 AudioService와 연동하거나 MainShell 위에 버튼을 따로 구현 가능
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }
}