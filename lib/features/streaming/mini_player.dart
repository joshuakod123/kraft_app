import 'package:flutter/material.dart';
import '../../common/widgets/glass_card.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: GlassCard(
        opacity: 0.8,
        borderColor: themeColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 앨범 커버
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note, color: themeColor),
              ),
              const SizedBox(width: 12),

              // 곡 정보
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KRAFT Demo Track 1",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                    ),
                    Text(
                      "Music Dept.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // 컨트롤러
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {},
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}