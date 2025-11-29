import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

class CurriculumItem {
  final int id;
  final int week;
  final String title;
  final String description;
  final DateTime date;
  final String status;

  CurriculumItem({required this.id, required this.week, required this.title, required this.description, required this.date, required this.status});

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    final weekNum = json['week_number'] as int;
    final eventDate = DateTime.now().add(Duration(days: (weekNum - 1) * 7));

    String status = 'upcoming';
    // 간단한 상태 로직 (날짜 비교 등은 여기서 고도화 가능)
    if (weekNum == 1) status = 'done';
    if (weekNum == 2) status = 'active';

    return CurriculumItem(
        id: json['id'], week: weekNum, title: json['title'] ?? 'Title',
        description: json['description'] ?? 'No description', date: eventDate, status: status
    );
  }
}

// [핵심] UI에서 watch하는 대상
final curriculumProvider = StreamProvider.autoDispose<List<CurriculumItem>>((ref) {
  final dept = ref.watch(currentDeptProvider);
  return SupabaseRepository().getCurriculumsStream(dept.id).map(
        (data) => data.map((e) => CurriculumItem.fromJson(e)).toList(),
  );
});