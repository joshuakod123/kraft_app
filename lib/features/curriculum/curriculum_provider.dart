import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../auth/auth_provider.dart'; // [필수] authProvider import 추가

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
  // 부서가 바뀌면 스트림 재연결
  return SupabaseRepository().getCurriculumsStream(dept.id).map((list) {
    return list.map((e) => CalendarEvent(
      id: e['id'],
      title: e['title'] ?? 'Official',
      description: e['description'] ?? '',
      // DB 컬럼명에 맞춰 파싱 (event_date가 없으면 created_at 등 대체)
      date: DateTime.parse(e['event_date'] ?? e['created_at']),
      isOfficial: true,
    )).toList();
  });
});

// 2. 개인 일정 스트림
final personalEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  // [핵심 수정] 로그인 상태가 변경되면 이 Provider를 다시 빌드하여 새로운 userId로 스트림을 연결합니다.
  ref.watch(authProvider);

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

// 3. 통합 데이터 제공
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final officialAsync = ref.watch(officialEventsProvider);
  final personalAsync = ref.watch(personalEventsProvider);

  final List<CalendarEvent> events = [];

  officialAsync.whenData((list) => events.addAll(list));
  personalAsync.whenData((list) => events.addAll(list));

  events.sort((a, b) => a.date.compareTo(b.date));

  return events;
});