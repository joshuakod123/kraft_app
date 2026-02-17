import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// [필수] 에러 해결을 위한 임포트
import '../../core/state/global_providers.dart';
import 'package:kraft_app/features/admin/manager_provider.dart';
import 'magazine_model.dart';

// 매거진 데이터 불러오기 Provider
final magazineListProvider = FutureProvider<List<Magazine>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('magazines')
      .select()
      .order('created_at', ascending: false);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((e) => Magazine.fromJson(e)).toList();
});

class MagazineListScreen extends ConsumerWidget {
  const MagazineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magazinesAsync = ref.watch(magazineListProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101010), // 깔끔한 블랙 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false, // 왼쪽 정렬로 변경하여 더 모던하게
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Magazine',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          if (isManager)
            IconButton(
              onPressed: () => context.push('/magazine_upload'),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            ),
        ],
      ),
      body: magazinesAsync.when(
        data: (magazines) {
          if (magazines.isEmpty) {
            return const Center(
              child: Text(
                "발행된 매거진이 없습니다.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          // [핵심 변경] PageView(슬라이더) -> ListView(세로 리스트)
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: magazines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 40),
            itemBuilder: (context, index) {
              final mag = magazines[index];
              return GestureDetector(
                onTap: () => context.push('/magazine_detail', extra: mag),
                child: _buildSimpleCard(context, mag),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(BuildContext context, Magazine mag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 이미지 영역 (16:9 비율로 깔끔하게)
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(mag.coverImageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. 텍스트 영역 (이미지 아래에 배치)
        Row(
          children: [
            // 날짜 태그
            Text(
              mag.createdAt.toString().split(' ')[0].replaceAll('-', '.'),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 10, color: Colors.grey[800]),
            const SizedBox(width: 8),
            const Text(
              "KRAFT WEEKLY",
              style: TextStyle(
                color: Color(0xFF6B4DFF), // 포인트 컬러 (보라빛)
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 제목
        Text(
          mag.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),

        // 부제목 (최대 2줄)
        Text(
          mag.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}