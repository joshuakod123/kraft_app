import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../magazine_model.dart';

// 홈 화면용 최신 매거진 3개 Provider
final homeLatestMagazineProvider = FutureProvider<List<Magazine>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('magazines')
      .select()
      .order('created_at', ascending: false)
      .limit(3);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((e) => Magazine.fromJson(e)).toList();
});

class MagazineHomePreview extends ConsumerWidget {
  const MagazineHomePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magazineAsync = ref.watch(homeLatestMagazineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [수정 1] 제목 변경: Latest Articles -> Weekly Kraft
              Text(
                "Weekly Kraft",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // [수정 2] View All 버튼 기능 연결
              InkWell(
                onTap: () {
                  // GoRouter에 '/magazine' 경로가 정의되어 있어야 합니다.
                  // 만약 바텀 네비게이션으로 이동해야 한다면 context.go('/magazine')을 사용하세요.
                  context.push('/magazine_list');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        magazineAsync.when(
          data: (magazines) {
            if (magazines.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("발행된 매거진이 없습니다.", style: TextStyle(color: Colors.white54)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: magazines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final mag = magazines[index];
                return GestureDetector(
                  onTap: () => context.push('/magazine_detail', extra: mag),
                  child: _buildPreviewCard(mag),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPreviewCard(Magazine mag) {
    return Container(
      color: Colors.transparent, // 클릭 영역 확보
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[900],
              image: DecorationImage(
                image: NetworkImage(mag.coverImageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WEEKLY ISSUE",
                  style: const TextStyle(
                    color: Color(0xFF6B4DFF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mag.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mag.createdAt.toString().split(' ')[0].replaceAll('-', '.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}