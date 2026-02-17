import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// [중요] 프로젝트 이름(kraft_app)이 맞는지 확인하세요. pubspec.yaml의 name과 동일해야 합니다.
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

// [클래스 정의] 이 부분이 반드시 있어야 에러가 사라집니다.
class MagazineListScreen extends ConsumerWidget {
  const MagazineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magazinesAsync = ref.watch(magazineListProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'KRAFT WEEKLY',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
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
            return const Center(child: Text("발행된 매거진이 없습니다.", style: TextStyle(color: Colors.white)));
          }
          return PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            scrollDirection: Axis.horizontal,
            itemCount: magazines.length,
            itemBuilder: (context, index) {
              final mag = magazines[index];
              return GestureDetector(
                onTap: () => context.push('/magazine_detail', extra: mag),
                child: _buildMagazineCard(context, mag),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildMagazineCard(BuildContext context, Magazine mag) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 80),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(mag.coverImageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
            stops: const [0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                mag.createdAt.toString().split(' ')[0],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mag.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mag.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Text(
                  "Read Article",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}