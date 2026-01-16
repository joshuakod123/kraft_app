import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../features/admin/manager_provider.dart';
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
              // [수정 4] 팝업 메뉴 아이템의 텍스트/아이콘 색상을 흰색으로 변경하여 가독성 개선
              if (isManager)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 28),
                  tooltip: '임원진 메뉴',
                  color: const Color(0xFF1E1E1E), // 팝업 배경색 (어두운 색)
                  onSelected: (value) {
                    if (value == 'qr') {
                      context.push('/qr_create');
                    } else if (value == 'list') {
                      context.push('/attendance_list');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2, color: Colors.white), // 흰색 아이콘
                          SizedBox(width: 10),
                          Text('출석 QR 생성', style: TextStyle(color: Colors.white)), // 흰색 텍스트
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'list',
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.white), // 흰색 아이콘
                          SizedBox(width: 10),
                          Text('출석 명단 확인', style: TextStyle(color: Colors.white)), // 흰색 텍스트
                        ],
                      ),
                    ),
                  ],
                ),

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
                    ],
                  ),
                  const SizedBox(height: 10),
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }
}