import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'widgets/dept_notice_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddNoticeDialog(BuildContext context, WidgetRef ref, int teamId) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("공지사항 등록", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: '내용',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                // [수정] 인자 3개 전달 (제목, 내용, 팀ID)
                await SupabaseRepository().addNotice(titleCtrl.text, contentCtrl.text, teamId);
                if (context.mounted) {
                  Navigator.pop(context);
                  // [수정] refresh -> invalidate (Provider 초기화)
                  ref.invalidate(noticeStreamProvider(teamId));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: const Text("등록"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: kAppBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text('KRAFT ${dept.name}', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [dept.color.withValues(alpha: 0.25), kAppBackgroundColor])),
                child: Center(child: Icon(dept.icon, size: 120, color: dept.color.withValues(alpha: 0.1))),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => context.push('/attendance_scan')),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NOTICE', style: TextStyle(color: dept.color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

                      // [수정] 매니저일 때 '이쁜 버튼' 표시
                      if (isManager)
                        FilledButton.tonalIcon(
                          onPressed: () => _showAddNoticeDialog(context, ref, dept.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: dept.color.withValues(alpha: 0.2),
                            foregroundColor: dept.color,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text("POST", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),

          // [핵심 수정] 하단 네비게이션 바에 가려지지 않도록 패딩 추가
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }
}