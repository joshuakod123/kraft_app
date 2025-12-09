import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;

  // --- Auth & Profile ---
  Future<String?> signIn({required String email, required String password}) async {
    try { await _client.auth.signInWithPassword(email: email, password: password); return null; } catch (e) { return e.toString(); }
  }
  Future<String?> signUp({required String email, required String password}) async {
    try { await _client.auth.signUp(email: email, password: password); return null; } catch (e) { return e.toString(); }
  }
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      return await _client.from('users').select().eq('id', userId).maybeSingle();
    } catch (e) { return null; }
  }
  Future<bool> updateUserProfile({
    required String name,
    required String major,
    required String phone,
    required int teamId,
    required String school,
    required String studentId,
    required String gender,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      await _client.from('users').upsert({
        'id': user.id, 'email': user.email, 'name': name,
        'major': major, 'phone': phone, 'team_id': teamId,
        'school': school, 'student_id': studentId,
        'gender': gender,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      return false; }
  }

  // --- [공식 일정] Curriculums (날짜 + 시간) ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client
        .from('curriculums')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId)
        .order('event_date', ascending: true);
  }

  // [수정] 종료 시간(endTime) 포함
  Future<bool> addCurriculum(String title, String desc, DateTime date, DateTime? endTime, int teamId) async {
    try {
      await _client.from('curriculums').insert({
        'title': title,
        'description': desc,
        'week_number': 0, // 필요시 계산 로직 추가
        'team_id': teamId,
        'event_date': date.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'semester_id': 1, // 기본값
      });
      return true;
    } catch (e) {
      debugPrint("Add Official Error: $e");
      return false;
    }
  }

  Future<bool> deleteCurriculum(int id) async {
    try { await _client.from('curriculums').delete().eq('id', id); return true; } catch (e) { return false; }
  }

  // --- [개인 일정] Personal Schedules (날짜 + 시간) ---
  Stream<List<Map<String, dynamic>>> getPersonalSchedulesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('personal_schedules')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('event_date', ascending: true);
  }

  // [수정] 종료 시간(endTime) 포함
  Future<bool> addPersonalSchedule(String title, String desc, DateTime date, DateTime? endTime) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('personal_schedules').insert({
        'user_id': userId,
        'title': title,
        'description': desc,
        'event_date': date.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Add Personal Error: $e");
      return false;
    }
  }

  Future<bool> deletePersonalSchedule(int id) async {
    try { await _client.from('personal_schedules').delete().eq('id', id); return true; } catch (e) { return false; }
  }

  // --- Notices ---
  Stream<List<Map<String, dynamic>>> getNoticesStream(int teamId) {
    return _client.from('notices').stream(primaryKey: ['id']).eq('team_id', teamId).order('created_at', ascending: false);
  }
  Future<bool> addNotice(String title, String content, int teamId) async {
    try { await _client.from('notices').insert({'title': title, 'content': content, 'team_id': teamId}); return true; } catch (e) { return false; }
  }
  Future<bool> deleteNotice(int id) async {
    try { await _client.from('notices').delete().eq('id', id); return true; } catch (e) { return false; }
  }

  // --- Archives (New) ---
  Stream<List<Map<String, dynamic>>> getMyArchivesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('archives')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> addArchive(String title, String description, String fileUrl) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('archives').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_type': 'image', // 기본값
      });
    } catch (e) {
      debugPrint("Add Archive Error: $e");
    }
  }
  // --- Team Members ---
  // 같은 부서의 멤버 리스트를 가져오는 함수 (임원진 -> 이름순 정렬)
  Future<List<Map<String, dynamic>>> getTeamMembers(int teamId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('team_id', teamId)
          .order('role', ascending: true) // manager(m)가 member(m)보다 뒤에 오므로 로직 처리 필요, 일단 가져옴
          .order('name', ascending: true);

      // 'manager'가 리스트 상단에 오도록 클라이언트 측 정렬 보정
      final List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(response);
      members.sort((a, b) {
        if (a['role'] == 'manager' && b['role'] != 'manager') return -1;
        if (a['role'] != 'manager' && b['role'] == 'manager') return 1;
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });

      return members;
    } catch (e) {
      debugPrint("Fetch Team Members Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client.from('assignments').select('*, curriculums(title)').eq('user_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<bool> uploadAssignment(int curriculumId) async { return false; } // 추후 구현

  Future<bool> markAttendance(String qrData) async {
    // QR 데이터 파싱 및 출석 처리 로직 (생략)
    return true;
  }

  Future<List<Map<String, dynamic>>> getTracks(int teamId) async { return []; }
}