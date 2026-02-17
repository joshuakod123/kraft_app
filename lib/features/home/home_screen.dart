import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../features/admin/manager_provider.dart';
import 'widgets/dept_notice_card.dart';
import 'widgets/home_magazine_section.dart'; // [NEW] 매거진 위젯 import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. 앱바 영역
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: kAppBackgroundColor, // 배경색 (상수 사용 가정)
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
              // 관리자 메뉴
              if (isManager)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 28),
                  tooltip: '임원진 메뉴',
                  color: const Color(0xFF1E1E1E),
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
                          Icon(Icons.qr_code_2, color: Colors.white),
                          SizedBox(width: 10),
                          Text('출석 QR 생성', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'list',
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.white),
                          SizedBox(width: 10),
                          Text('출석 명단 확인', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              // 출석 스캔 버튼
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => context.push('/attendance_scan'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. 공지사항 섹션 (좌우 패딩 16 적용)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                  const SizedBox(height: 10),
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),

          // 3. [NEW] 매거진 섹션 (패딩은 위젯 내부에서 처리하여 더 넓게 표현)
          const SliverToBoxAdapter(
            child: HomeMagazineSection(),
          ),

          // 하단 여백 확보
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }
}