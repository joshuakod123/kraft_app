import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kraft_app/common/widgets/glass_card.dart';

class HomeMagazineSection extends StatelessWidget {
  const HomeMagazineSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 테마 색상 참조
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 섹션 헤더 (Title & More)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly Kraft",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // 다크모드/라이트모드 대응 (기본 텍스트 색상)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "이번 주 학회 인사이트를 확인하세요",
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              // 전체보기 버튼
              TextButton(
                onPressed: () {
                  // TODO: 매거진 전체 리스트 화면으로 이동
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. 메인 피쳐 카드 (가장 최신 글)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildFeaturedCard(context),
        ),

        const SizedBox(height: 24),

        // 3. 지난 호 리스트 (가로 스크롤)
        SizedBox(
          height: 180, // 리스트 높이
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: 5, // 임시 개수
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildSmallMagazineCard(context, index);
            },
          ),
        ),

        const SizedBox(height: 32), // 하단 여백
      ],
    );
  }

  // --- 메인(Hero) 카드 위젯 ---
  Widget _buildFeaturedCard(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 시네마틱 비율
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
          image: const DecorationImage(
            // 임시 이미지 (나중에 Supabase URL로 교체)
            image: NetworkImage("https://images.unsplash.com/photo-1550751827-4bd374c3f58b"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // 이미지 위에 그라데이션 오버레이 (글씨 잘 보이게)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "NEW ISSUE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "AI 시대, 주니어 개발자의 생존 전략",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=a"),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Joshua Kim • 2 Feb",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 작은(리스트) 카드 위젯 ---
  Widget _buildSmallMagazineCard(BuildContext context, int index) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage("https://picsum.photos/200/300?random=$index"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 제목
          Text(
            "Flutter 3.0 업데이트 총정리",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Vol. ${23 - index}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}