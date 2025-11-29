import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/department_enum.dart';
import '../../../core/data/supabase_repository.dart';
import '../../../core/state/global_providers.dart';

// 공지사항 스트림 프로바이더
final noticeStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, int>((ref, teamId) {
  return SupabaseRepository().getNoticesStream(teamId);
});

class DeptNoticeCard extends ConsumerWidget {
  final Department dept;

  const DeptNoticeCard({super.key, required this.dept});

  // [수정] 안정적인 Dialog로 교체 (Blank 화면 해결)
  void _showFancyDetail(BuildContext context, Map<String, dynamic> notice) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8), // 배경 어둡게
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 블러 효과
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: GlassContainer.clearGlass(
              height: 500,
              width: double.infinity,
              borderRadius: BorderRadius.circular(24),
              borderWidth: 1.0,
              // [수정] 하이라이트 완화 (은은하게)
              borderColor: dept.color.withValues(alpha: 0.3),
              elevation: 10,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dept.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: dept.color.withValues(alpha: 0.3)),
                        ),
                        child: Text("NOTICE", style: TextStyle(color: dept.color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      // [닫기 버튼] 이제 정상 작동함
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    notice['title'] ?? 'No Title',
                    style: GoogleFonts.chakraPetch(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice['created_at'] != null
                        ? DateFormat('yyyy.MM.dd').format(DateTime.parse(notice['created_at']).toLocal())
                        : '',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        notice['content'] ?? '',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = ref.watch(isManagerProvider);
    final asyncNotices = ref.watch(noticeStreamProvider(dept.id));

    return asyncNotices.when(
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => Text('Error loading notice', style: TextStyle(color: Colors.red[300])),
      data: (notices) {
        if (notices.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.info_outline, color: dept.color, size: 20), const SizedBox(width: 8), Text('NOTICE', style: TextStyle(color: dept.color, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                const Text("현재 등록된 공지사항이 없습니다.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final notice = notices.first;
        final int noticeId = notice['id'];

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _showFancyDetail(context, notice),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dept.color.withValues(alpha: 0.2)), // [수정] 테두리 연하게
              boxShadow: [BoxShadow(color: dept.color.withValues(alpha: 0.05), blurRadius: 10)], // [수정] 그림자 연하게
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Icon(Icons.campaign, color: dept.color, size: 20), const SizedBox(width: 8), Text('LATEST NOTICE', style: TextStyle(color: dept.color, fontWeight: FontWeight.bold, fontSize: 12))]),

                    // [삭제 버튼]
                    if (isManager)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text("삭제하시겠습니까?", style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await SupabaseRepository().deleteNotice(noticeId);
                              // [핵심] invalidate 대신 refresh 사용하여 더 강력하게 갱신
                              ref.refresh(noticeStreamProvider(dept.id));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(notice['title'] ?? '제목 없음', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(notice['content'] ?? '', style: TextStyle(color: Colors.grey[400], height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ).animate().fadeIn(),
        );
      },
    );
  }
}