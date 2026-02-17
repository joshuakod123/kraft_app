import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // [FIX] Supabase import 추가

import '../../core/data/supabase_repository.dart';
import '../../features/admin/manager_provider.dart'; // [FIX] import 추가
import 'magazine_model.dart'; // 모델 파일 import (같은 폴더에 있다고 가정)

// 매거진 데이터 프로바이더
final magazineListProvider = FutureProvider<List<Magazine>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('magazines')
      .select()
      .order('created_at', ascending: false);

  // 데이터가 리스트 형태인지 확인 후 변환
  final List<dynamic> data = response as List<dynamic>;
  return data.map((e) => Magazine.fromJson(e)).toList();
});

class MagazineListScreen extends ConsumerWidget {
  const MagazineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magazinesAsync = ref.watch(magazineListProvider);
    final isManager = ref.watch(isManagerProvider); // 이제 에러 안 남

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 1. 헤더
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.black,
            title: Text(
              'Kraft Archives',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              // 임원일 때만 (+) 버튼 표시
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () => context.push('/magazine_upload'),
                ),
            ],
          ),

          // 2. 리스트 그리드
          magazinesAsync.when(
            data: (magazines) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final mag = magazines[index];
                    return GestureDetector(
                      onTap: () => context.push('/magazine_detail', extra: mag),
                      child: _buildMagazineItem(context, mag),
                    );
                  },
                  childCount: magazines.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white)))),
          ),
        ],
      ),
    );
  }

  Widget _buildMagazineItem(BuildContext context, Magazine mag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(mag.coverImageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mag.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          mag.subtitle,
          maxLines: 1,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}