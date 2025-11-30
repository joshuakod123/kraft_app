import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../auth/auth_provider.dart';

class CalendarEvent {
  final int id;
  final String title;
  final String description;
  final DateTime date;     // 시작 시간
  final DateTime? endTime; // 종료 시간 (추가됨)
  final bool isOfficial;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endTime,
    required this.isOfficial,
  });
}

// 1. 공식 일정 스트림
final officialEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final dept = ref.watch(currentDeptProvider);
  return SupabaseRepository().getCurriculumsStream(dept.id).map((list) {
    return list.map((e) => CalendarEvent(
      id: e['id'],
      title: e['title'] ?? 'Official',
      description: e['description'] ?? '',
      date: DateTime.parse(e['event_date'] ?? e['created_at']),
      endTime: e['end_time'] != null ? DateTime.parse(e['end_time']) : null,
      isOfficial: true,
    )).toList();
  });
});

// 2. 개인 일정 스트림
final personalEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  ref.watch(authProvider); // 계정 변경 감지
  return SupabaseRepository().getPersonalSchedulesStream().map((list) {
    return list.map((e) => CalendarEvent(
      id: e['id'],
      title: e['title'] ?? 'Personal',
      description: e['description'] ?? '',
      date: DateTime.parse(e['event_date']),
      endTime: e['end_time'] != null ? DateTime.parse(e['end_time']) : null,
      isOfficial: false,
    )).toList();
  });
});

// 3. 통합 데이터 제공
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final officialAsync = ref.watch(officialEventsProvider);
  final personalAsync = ref.watch(personalEventsProvider);

  final List<CalendarEvent> events = [];
  officialAsync.whenData((list) => events.addAll(list));
  personalAsync.whenData((list) => events.addAll(list));

  // 날짜순 정렬
  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
});