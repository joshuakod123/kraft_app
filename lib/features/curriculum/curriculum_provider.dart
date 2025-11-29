import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

// [통합 일정 모델]
class CalendarEvent {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final bool isOfficial; // True: 공식(Cyan), False: 개인(Purple)

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
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
      date: DateTime.parse(e['event_date']),
      isOfficial: true,
    )).toList();
  });
});

// 2. 개인 일정 스트림
final personalEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  return SupabaseRepository().getPersonalSchedulesStream().map((list) {
    return list.map((e) => CalendarEvent(
      id: e['id'],
      title: e['title'] ?? 'Personal',
      description: e['description'] ?? '',
      date: DateTime.parse(e['event_date']),
      isOfficial: false,
    )).toList();
  });
});

// 3. [핵심] 두 데이터를 합쳐서 UI에 제공 (UI는 이것만 구독하면 됨)
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final officialAsync = ref.watch(officialEventsProvider);
  final personalAsync = ref.watch(personalEventsProvider);

  final List<CalendarEvent> events = [];

  // 데이터가 로드된 상태라면 리스트에 추가
  officialAsync.whenData((list) => events.addAll(list));
  personalAsync.whenData((list) => events.addAll(list));

  // 날짜순 정렬
  events.sort((a, b) => a.date.compareTo(b.date));

  return events;
});