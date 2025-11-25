import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../common/widgets/glass_card.dart';
import '../../core/utils/date_utils.dart';
import 'curriculum_provider.dart';

class CurriculumListScreen extends ConsumerWidget {
  const CurriculumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FutureProvider는 AsyncValue를 반환합니다.
    final curriculumAsync = ref.watch(curriculumListProvider);
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('CURRICULUM')),

      // 데이터 로딩 상태에 따른 분기 처리 (.when 사용)
      body: curriculumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (curriculumList) {
          if (curriculumList.isEmpty) {
            return const Center(child: Text('등록된 커리큘럼이 없습니다.', style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: curriculumList.length,
            itemBuilder: (context, index) {
              final item = curriculumList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  onTap: () => context.push('/assignment_upload', extra: item),
                  borderColor: item.isSubmitted ? themeColor : Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'WEEK ${item.week}',
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isSubmitted ? themeColor : Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isSubmitted ? 'SUBMITTED' : KraftDateUtils.getDday(item.deadline),
                                style: TextStyle(
                                  color: item.isSubmitted ? Colors.black : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(item.description, style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (100 * index).ms).slideX(),
              );
            },
          );
        },
      ),
    );
  }
}