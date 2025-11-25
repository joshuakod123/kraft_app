import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 전역 상태에서 현재 부서와 관리자 여부를 가져옵니다.
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic AppBar with Gradient
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
                      dept.color.withOpacity(0.25), // 상단부 팀 컬러
                      kAppBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    dept.icon,
                    size: 120,
                    color: dept.color.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            actions: [
              // 관리자 전용 버튼
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: dept.color,
                  tooltip: 'Add Curriculum',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('[Manager] 커리큘럼 추가 모드'),
                        backgroundColor: dept.color,
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Department Notice Board
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dept.color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🔥 이번 주 정기 세션 안내",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "장소: 경영관 B103호\n시간: 금요일 18:00\n준비물: 개인 노트북 및 열정",
                          style: TextStyle(color: Colors.grey[400], height: 1.5),
                        ),
                      ],
                    ),
                  ).animate().slideX(duration: 500.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ),

          // 3. Curriculum Timeline
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
                childCount: 8, // 8주차 예시
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
        // 선택 시 미세한 테두리 효과 (나중에 Interaction 추가)
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
                  color: deptColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'WEEK $week',
                  style: TextStyle(
                    color: deptColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Interactive Media Design Project',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Using Flutter & Supabase to create something cool.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.circle_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text('Pending', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}