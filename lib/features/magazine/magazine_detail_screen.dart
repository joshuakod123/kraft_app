import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'magazine_model.dart';

class MagazineDetailScreen extends StatelessWidget {
  final Magazine magazine;

  const MagazineDetailScreen({super.key, required this.magazine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 어두운 배경
      body: CustomScrollView(
        slivers: [
          // 1. 대형 커버 이미지
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                magazine.coverImageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          // 2. 본문 내용
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 & 작성자
                  Text(
                    "Published on ${magazine.createdAt.toString().split(' ')[0]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // 제목
                  Text(
                    magazine.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 부제목
                  Text(
                    magazine.subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Divider(height: 40, color: Colors.grey),

                  // 마크다운 본문 (flutter_markdown 패키지 필요)
                  MarkdownBody(
                    data: magazine.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                      h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 100), // 하단 여백
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}