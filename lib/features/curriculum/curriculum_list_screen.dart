import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'curriculum_provider.dart';

class CurriculumListScreen extends ConsumerWidget {
  const CurriculumListScreen({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref, int teamId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weekCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Add Curriculum", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: weekCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Week', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                final week = int.tryParse(weekCtrl.text) ?? 0;
                await SupabaseRepository().addCurriculum(titleCtrl.text, descCtrl.text, week, teamId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.refresh(curriculumProvider);
                }
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCurriculum = ref.watch(curriculumProvider);
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            pinned: true,
            expandedHeight: 120.0,
            actions: [
              if (isManager)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: dept.color, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                  onPressed: () => _showAddDialog(context, ref, dept.id),
                ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('SEASON PLAN', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          asyncCurriculum.when(
            data: (list) {
              if (list.isEmpty) return const SliverFillRemaining(child: Center(child: Text("일정이 없습니다.", style: TextStyle(color: Colors.grey))));
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = list[index];
                    return _TimelineItem(
                        item: item, isLast: index == list.length - 1, deptColor: dept.color, isManager: isManager
                    ).animate().fadeIn(delay: (50 * index).ms).slideX();
                  },
                  childCount: list.length,
                ),
              );
            },
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error', style: const TextStyle(color: Colors.red)))),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final CurriculumItem item;
  final bool isLast;
  final Color deptColor;
  final bool isManager;

  const _TimelineItem({required this.item, required this.isLast, required this.deptColor, required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = item.status == 'active';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(DateFormat('MM.dd').format(item.date), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isActive ? deptColor : Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? deptColor : Colors.black, border: Border.all(color: isActive ? deptColor : Colors.grey[800]!, width: 2)),
                ),
                Expanded(child: isLast ? const SizedBox.shrink() : Container(width: 2, margin: const EdgeInsets.only(top: 4), color: Colors.grey[900])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: () => context.push('/assignment_upload', extra: item),
                child: GlassContainer.clearGlass(
                  height: 120, width: double.infinity, borderRadius: BorderRadius.circular(16),
                  borderWidth: 1.0,
                  // [수정] 하이라이트 대폭 완화
                  borderColor: isActive ? deptColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('WEEK ${item.week}', style: TextStyle(color: isActive ? deptColor : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(item.description, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1),
                        ],
                      ),
                      if (isManager)
                        Positioned(
                          top: 0, right: 0,
                          child: InkWell(
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
                                await SupabaseRepository().deleteCurriculum(item.id);
                                // [핵심] 삭제 후 강제 새로고침
                                ref.refresh(curriculumProvider);
                              }
                            },
                            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}