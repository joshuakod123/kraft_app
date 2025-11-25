import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/department_enum.dart';
import '../../../core/data/supabase_repository.dart';

class DeptNoticeCard extends StatelessWidget {
  final Department dept;

  const DeptNoticeCard({super.key, required this.dept});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseRepository().getNotices(dept.id),
      builder: (context, snapshot) {
        // 1. 로딩 중일 때 보여줄 화면
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // 2. [핵심 수정] 데이터가 비어있거나 에러가 났을 때 "공지 없음" 처리
        // 이 부분이 없어서 가입 직후 앱이 튕겼던 것입니다.
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                Row(
                  children: [
                    Icon(Icons.info_outline, color: dept.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'NOTICE',
                      style: TextStyle(
                        color: dept.color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "현재 등록된 공지사항이 없습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 3. 데이터가 있을 때만 실행됨 (이제 안전함!)
        final notice = snapshot.data!.first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dept.color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: dept.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: dept.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LATEST NOTICE',
                    style: TextStyle(
                      color: dept.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice['title'] ?? '제목 없음',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notice['content'] ?? '',
                style: TextStyle(color: Colors.grey[400], height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: 0.1, end: 0);
      },
    );
  }
}