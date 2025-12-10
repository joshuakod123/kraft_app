import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../common/widgets/glass_card.dart';
import 'stream_screen.dart';

class MiniPlayer extends StatelessWidget {
  final MediaItem song;

  const MiniPlayer({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // [UX 핵심] Root Navigator를 사용하여 탭바 위로 페이지를 띄움
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, __) => StreamScreen(mediaItem: song),
            transitionsBuilder: (context, animation, __, child) {
              // 유튜브 뮤직처럼 아래에서 위로 올라오는 슬라이드 애니메이션
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.fastOutSlowIn;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            opaque: false, // 배경이 투명하게 보일 수 있도록 (필요시)
          ),
        );
      },
      child: GlassCard(
        opacity: 0.95,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. 앨범 아트 (Hero 애니메이션 연결)
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

              // 2. 제목 및 가수
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // 3. 컨트롤 버튼 (디자인용)
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}