import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';

// 모델 정의
class CurriculumItem {
  final int id;
  final int week;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isSubmitted; // 나중에 과제 테이블과 조인해서 확인 필요

  CurriculumItem({
    required this.id,
    required this.week,
    required this.title,
    required this.description,
    required this.deadline,
    this.isSubmitted = false,
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    return CurriculumItem(
      id: json['id'],
      week: json['week_number'],
      title: json['title'],
      description: json['description'] ?? '',
      deadline: DateTime.parse(json['deadline']),
      isSubmitted: false,
    );
  }
}

// Repository Provider
final supabaseRepositoryProvider = Provider((ref) => SupabaseRepository());

// 데이터 Fetch Provider (FutureProvider 사용)
final curriculumListProvider = FutureProvider<List<CurriculumItem>>((ref) async {
  final repo = ref.watch(supabaseRepositoryProvider);

  // DB에서 데이터 가져오기
  final data = await repo.getCurriculums();

  if (data.isEmpty) {
    return []; // 데이터가 없으면 빈 리스트
  }

  return data.map((json) => CurriculumItem.fromJson(json)).toList();
});