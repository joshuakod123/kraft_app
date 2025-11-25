import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _userName = '';

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
                  // [추가] 환영 인사
                  if (_userName.isNotEmpty)
                    Text(
                      'Welcome, $_userName',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ).animate().fadeIn(),

                  Text(
                    'KRAFT ${dept.name}',
                    style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
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
                  child: Icon(dept.icon, size: 120, color: dept.color.withValues(alpha: 0.1)),
                ),
              ),
            ),
            actions: [
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
          // ... (나머지 내용은 기존 유지)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DeptNoticeCard(dept: dept),
                ],
              ),
            ),
          ),
          // ...
        ],
      ),
    );
  }
}