import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';

// 커리큘럼 아이템 모델 확장
class CurriculumItem {
  final int id;
  final int week;
  final String title;
  final String description;
  final DateTime date;
  final String status; // 'done', 'active', 'upcoming'

  CurriculumItem({
    required this.id,
    required this.week,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    // 날짜가 없으면 임의로 생성 (현재 주차 기준)
    final weekNum = json['week_number'] as int;
    final now = DateTime.now();
    // 예시: 1주차는 3주 전이라고 가정
    final eventDate = now.add(Duration(days: (weekNum - 3) * 7));

    String status = 'upcoming';
    if (eventDate.isBefore(now.subtract(const Duration(days: 1)))) {
      status = 'done';
    } else if (eventDate.isBefore(now.add(const Duration(days: 6)))) {
      status = 'active';
    }

    return CurriculumItem(
      id: json['id'],
      week: weekNum,
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'Detailed session description goes here.',
      date: eventDate,
      status: status,
    );
  }
}

class CurriculumNotifier extends Notifier<List<CurriculumItem>> {
  final _repo = SupabaseRepository();

  @override
  List<CurriculumItem> build() {
    _loadCurriculums();
    return [];
  }

  Future<void> _loadCurriculums() async {
    final data = await _repo.getCurriculums();
    state = data.map((e) => CurriculumItem.fromJson(e)).toList();
  }
}

final curriculumProvider = NotifierProvider<CurriculumNotifier, List<CurriculumItem>>(CurriculumNotifier.new);