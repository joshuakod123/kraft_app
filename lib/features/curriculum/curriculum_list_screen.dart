import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import 'curriculum_provider.dart';

class CurriculumListScreen extends ConsumerWidget {
  const CurriculumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumList = ref.watch(curriculumProvider);
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // [헤더] Fancy Title
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            pinned: true,
            expandedHeight: 140.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'SEASON PLAN',
                style: GoogleFonts.chakraPetch(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              background: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dept.color.withValues(alpha: 0.3),
                        boxShadow: [BoxShadow(blurRadius: 80, color: dept.color)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // [리스트] 타임라인
          if (curriculumList.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = curriculumList[index];
                    final isLast = index == curriculumList.length - 1;
                    return _TimelineItem(
                      item: item,
                      isLast: isLast,
                      deptColor: dept.color,
                    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
                  },
                  childCount: curriculumList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final CurriculumItem item;
  final bool isLast;
  final Color deptColor;

  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.deptColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == 'active';
    final isDone = item.status == 'done';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 타임라인 (날짜 + 선 + 점)
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  DateFormat('MM.dd').format(item.date),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isActive ? deptColor : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? deptColor : (isDone ? Colors.grey[800] : Colors.black),
                    border: Border.all(
                      color: isActive ? deptColor : Colors.grey[600]!,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [BoxShadow(color: deptColor, blurRadius: 12, spreadRadius: 2)]
                        : [],
                  ),
                ),

                // Line
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isActive ? deptColor : Colors.grey[800]!,
                          Colors.grey[900]!,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 2. 컨텐츠 카드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: GestureDetector(
                onTap: () {
                  // 과제 제출 페이지로 이동
                  context.push('/assignment_upload', extra: item);
                },
                child: GlassContainer.clearGlass(
                  height: isActive ? 160 : 130, // 활성화된 카드는 더 크게
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(20),
                  borderWidth: 1.5,
                  borderColor: isActive
                      ? deptColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.1),
                  elevation: isActive ? 10 : 0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? deptColor : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'WEEK ${item.week}',
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: deptColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text("NOW", style: TextStyle(color: deptColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.grey : Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
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