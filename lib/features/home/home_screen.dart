import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart'; // go_router 추가
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import 'widgets/dept_notice_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: kAppBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'KRAFT ${dept.name}',
                style: GoogleFonts.chakraPetch(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dept.color.withValues(alpha: 0.25),
                      kAppBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    dept.icon,
                    size: 120,
                    color: dept.color.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            actions: [
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: dept.color,
                  onPressed: () => context.push('/qr_create'), // 관리자용 QR 생성
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                // [수정] QR 스캔 화면으로 이동
                onPressed: () => context.push('/attendance_scan'),
              ),
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
                    children: [
                      Icon(Icons.campaign, color: dept.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NOTICE FOR ${dept.name}',
                        style: TextStyle(
                          color: dept.color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // [수정] 실제 데이터를 받아오는 위젯
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),

          // ... (Curriculum List 등 기존 코드 유지) ...
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final weekNum = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _CurriculumCard(
                      week: weekNum,
                      deptColor: dept.color,
                    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1),
                  );
                },
                childCount: 4, // 일단 4개만
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CurriculumCard extends StatelessWidget {
  final int week;
  final Color deptColor;

  const _CurriculumCard({required this.week, required this.deptColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deptColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('WEEK $week', style: TextStyle(color: deptColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Interactive Media Design', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}