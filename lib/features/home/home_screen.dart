import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 추가
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'widgets/dept_notice_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _userName = 'Member';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final profile = await SupabaseRepository().getUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _userName = profile['name'] ?? 'Member';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: kAppBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              centerTitle: false,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $_userName', // [수정] 사용자 이름 표시
                    style: GoogleFonts.inter(
                      fontSize: 10, // 작게 표시
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    'KRAFT ${dept.name}',
                    style: GoogleFonts.chakraPetch(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
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
              // 관리자일 때만 QR 생성 버튼 보임
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: dept.color,
                  onPressed: () => context.push('/qr_create'),
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => context.push('/attendance_scan'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ... (이하 기존 코드 동일: Notice, Curriculum 등)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... 기존 Notice Card 코드 ...
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
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),

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
                childCount: 4,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// _CurriculumCard 클래스는 기존과 동일하므로 유지해주세요.
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