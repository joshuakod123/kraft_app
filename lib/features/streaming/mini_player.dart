import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../common/widgets/glass_card.dart';
import 'stream_screen.dart'; // StreamScreen import 필수

class MiniPlayer extends StatelessWidget {
  final MediaItem song; // 부모에게서 받은 곡 정보

  const MiniPlayer({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // [핵심] 탭하면 전체 화면 플레이어로 전환 (네비게이션 바 덮음)
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, __) => StreamScreen(mediaItem: song),
            transitionsBuilder: (context, animation, __, child) {
              // 아래에서 위로 올라오는 애니메이션
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
                child: child,
              );
            },
          ),
        );
      },
      child: GlassCard(
        opacity: 0.95,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. 앨범 아트
              Hero(
                tag: 'albumArt_${song.id}', // Hero 애니메이션 연결
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

              // 2. 곡 제목 & 가수
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                    Text(song.artist ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1),
                  ],
                ),
              ),

              // 3. Play/Pause 버튼 (지금은 UI만)
              const Icon(Icons.pause_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}