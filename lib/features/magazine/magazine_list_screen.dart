import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/global_providers.dart'; // [체크] 이 경로가 맞는지 확인
import 'magazine_model.dart';

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
    // 관리자 권한 확인 (auth_provider에서 설정됨)
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        scrolledUnderElevation: 0,
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
          // [핵심] 관리자 권한이 있을 때만 업로드 버튼 표시
          if (isManager)
            IconButton(
              onPressed: () async {
                // 업로드 후 돌아왔을 때 목록 새로고침
                await context.push('/magazine_upload');
                ref.refresh(magazineListProvider);
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: magazinesAsync.when(
        data: (magazines) {
          if (magazines.isEmpty) {
            return const Center(child: Text("발행된 매거진이 없습니다.", style: TextStyle(color: Colors.white54)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: magazines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 40),
            itemBuilder: (context, index) {
              final mag = magazines[index];
              return GestureDetector(
                onTap: () => context.push('/magazine_detail', extra: mag),
                child: _buildSimpleCard(mag),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildSimpleCard(Magazine mag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            image: DecorationImage(
              image: NetworkImage(mag.coverImageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              mag.createdAt.toString().split(' ')[0].replaceAll('-', '.'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 10, color: Colors.grey[800]),
            const SizedBox(width: 8),
            const Text(
              "KRAFT WEEKLY",
              style: TextStyle(color: Color(0xFF6B4DFF), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mag.title,
          style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          mag.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }
}