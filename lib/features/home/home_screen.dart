import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../community/community_screen.dart'; // [필수] 위에서 만든 파일 import
import 'widgets/dept_notice_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('KRAFT ${dept.name}', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [dept.color.withOpacity(0.25), Colors.black])),
                child: Center(child: Icon(dept.icon, size: 100, color: dept.color.withOpacity(0.1))),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [신규 기능] 커뮤니티 이동 버튼
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dept.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.forum, color: dept.color, size: 30),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("COMMUNITY HUB", style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text("Discuss homework & Share songs", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('NOTICE', style: TextStyle(color: dept.color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}