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

class DeptNoticeCard extends ConsumerStatefulWidget {
  final Department dept;

  const DeptNoticeCard({super.key, required this.dept});

  @override
  ConsumerState<DeptNoticeCard> createState() => _DeptNoticeCardState();
}

class _DeptNoticeCardState extends ConsumerState<DeptNoticeCard> {
  final _noticeController = TextEditingController();

  // Dialog 로직: HomeScreen에 있는 것과 동일하게 작동하도록 구성
  void _showAddNoticeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('새 공지 작성', style: GoogleFonts.chakraPetch(color: Colors.white)),
        content: TextField(
          controller: _noticeController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '내용을 입력하세요',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.black54,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_noticeController.text.isNotEmpty) {
                // [수정] 제목, 내용, ID 순서 및 타입 준수
                await SupabaseRepository().addNotice("Notice", _noticeController.text, widget.dept.id);

                if (mounted) {
                  ref.invalidate(noticeStreamProvider(widget.dept.id));
                  Navigator.pop(context);
                  _noticeController.clear();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.dept.color, foregroundColor: Colors.black),
            child: const Text('등록', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFancyDetail(BuildContext context, Map<String, dynamic> notice) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: GlassContainer.clearGlass(
              height: 500,
              width: double.infinity,
              borderRadius: BorderRadius.circular(24),
              borderWidth: 1.0,
              borderColor: widget.dept.color.withValues(alpha: 0.3),
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
                          color: widget.dept.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.dept.color.withValues(alpha: 0.3)),
                        ),
                        child: Text("NOTICE", style: TextStyle(color: widget.dept.color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
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
  Widget build(BuildContext context) {
    final isManager = ref.watch(isManagerProvider);
    final asyncNotices = ref.watch(noticeStreamProvider(widget.dept.id));

    return Column(
      children: [
        asyncNotices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
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
                child: const Text("공지사항이 없습니다.", style: TextStyle(color: Colors.grey)),
              );
            }

            // 가장 최신 공지 하나만 보여주거나 리스트로 보여줄 수 있음
            // 여기서는 카드 형태로 최신 공지 표시
            final notice = notices.first;
            final noticeId = notice['id'];

            return GestureDetector(
              onTap: () => _showFancyDetail(context, notice),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.dept.color.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: widget.dept.color.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [Icon(Icons.campaign, color: widget.dept.color, size: 20), const SizedBox(width: 8), Text('LATEST', style: TextStyle(color: widget.dept.color, fontWeight: FontWeight.bold, fontSize: 12))]),
                        if (isManager)
                          GestureDetector(
                            onTap: () async {
                              await SupabaseRepository().deleteNotice(noticeId);
                              ref.invalidate(noticeStreamProvider(widget.dept.id));
                            },
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          )
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
        ),

        // [수정] 매니저용 하단 추가 버튼 (디자인 개선)
        if (isManager)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: GestureDetector(
              onTap: () => _showAddNoticeDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.dept.color.withValues(alpha: 0.3),
                    width: 1.5,
                    style: BorderStyle.solid, // Flutter 기본 Border로는 점선이 안되어 투명도 조절로 대체
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: widget.dept.color),
                    const SizedBox(width: 8),
                    Text(
                      "새로운 공지 등록하기",
                      style: GoogleFonts.chakraPetch(
                        color: widget.dept.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}