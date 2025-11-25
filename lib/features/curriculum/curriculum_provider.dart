import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurriculumItem {
  final int week;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isSubmitted;

  CurriculumItem({
    required this.week,
    required this.title,
    required this.description,
    required this.deadline,
    this.isSubmitted = false,
  });
}

// 더미 데이터 제공 (실제로는 Supabase에서 fetch)
final curriculumListProvider = Provider<List<CurriculumItem>>((ref) {
  return [
    CurriculumItem(
      week: 1,
      title: 'Orientation & Ideation',
      description: '팀 빌딩 및 아이디어 스케치 제출',
      deadline: DateTime.now().add(const Duration(days: 2)),
      isSubmitted: true,
    ),
    CurriculumItem(
      week: 2,
      title: 'MVP Prototyping',
      description: '핵심 기능 구현 및 시연 영상',
      deadline: DateTime.now().add(const Duration(days: 9)),
      isSubmitted: false,
    ),
    CurriculumItem(
      week: 3,
      title: 'User Feedback & Iteration',
      description: '피드백 반영 및 고도화',
      deadline: DateTime.now().add(const Duration(days: 16)),
      isSubmitted: false,
    ),
  ];
});