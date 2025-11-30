import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

// 아카이브 데이터 프로바이더
final myArchiveProvider = StreamProvider((ref) => SupabaseRepository().getMyArchivesStream());

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivesAsync = ref.watch(myArchiveProvider);
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 1. 헤더 영역
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'MY ARCHIVE',
                style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [dept.color.withOpacity(0.2), Colors.black],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: () {
                  // 여기에 파일 업로드 기능 연결 (임시로 다이얼로그)
                  _showUploadDialog(context, dept.color);
                },
              ),
            ],
          ),

          // 2. 그리드 갤러리 영역
          archivesAsync.when(
            data: (archives) {
              if (archives.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No archived projects yet.", style: TextStyle(color: Colors.grey))),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2열 그리드
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75, // 세로로 긴 카드 비율 (포트폴리오 느낌)
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = archives[index];
                      return _buildArchiveCard(item, dept.color);
                    },
                    childCount: archives.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red)))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(Map<String, dynamic> item, Color themeColor) {
    return GlassContainer.clearGlass(
      height: double.infinity,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      borderWidth: 1.0,
      borderColor: Colors.white.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 이미지 영역
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: item['file_url'] != null
                    ? DecorationImage(image: NetworkImage(item['file_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: item['file_url'] == null
                  ? Icon(Icons.folder_open, color: themeColor.withOpacity(0.5), size: 48)
                  : null,
            ),
          ),
          // 텍스트 영역
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, Color color) {
    // 임시 업로드 다이얼로그 (실제로는 파일 피커 연동 필요)
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Archive Project", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, color: Colors.grey), SizedBox(width: 8), Text("Select Image (Dummy)", style: TextStyle(color: Colors.grey))]),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // 더미 데이터 추가
              await SupabaseRepository().addArchive(titleCtrl.text, descCtrl.text, "https://picsum.photos/400/600"); // 랜덤 이미지
              if(context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}