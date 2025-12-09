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
  //streaming
  // lib/core/data/supabase_repository.dart 내용에 추가

  // --- [Music Social Features] ---

  // 1. 댓글 가져오기 (작성자 정보 포함)
  Stream<List<Map<String, dynamic>>> getSongComments(int songId) {
    return _supabase
        .from('song_comments')
        .stream(primaryKey: ['id'])
        .eq('song_id', songId)
        .order('created_at', ascending: false) // 최신순
        .map((rows) async {
      // Stream은 join이 까다로우므로, 데이터가 올 때마다 유저 정보를 매핑하거나
      // 더 간단하게는 Future로 구현하는 것이 일반적이나, 실시간성을 위해 이렇게 처리합니다.
      // *Supabase의 .select('*, users(*)') 구문은 Stream에서 제한적이므로
      // 간단하게 Future 방식을 StreamController로 감싸거나, 여기서는 Future 호출 방식을 추천합니다.
      // 하지만 UI에서 StreamBuilder를 쓰기 위해 여기서는 .select()를 쓴 Future 함수를 만듭니다.
      return rows;
    })
        .asyncMap((event) async {
      // 팁: 복잡한 조인이 필요한 실시간 채팅은 단순 polling이나
      // DB Function을 쓰기도 하지만, 여기서는 가장 쉬운 select query로 대체합니다.
      return [];
    });
  }

  // [수정] 댓글 가져오기 (실시간 포기하고 Future로 구현 - 조인이 쉬움)
  Future<List<Map<String, dynamic>>> fetchComments(int songId) async {
    try {
      final response = await _supabase
          .from('song_comments')
          .select('*, users(name, cohort, id)') // users 테이블 조인
          .eq('song_id', songId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 2. 댓글 작성
  Future<void> addComment(int songId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('song_comments').insert({
      'song_id': songId,
      'user_id': userId,
      'content': content,
    });
  }

  // 3. 좋아요 상태 확인
  Future<bool> isSongLiked(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('song_likes')
        .select()
        .eq('user_id', userId)
        .eq('song_id', songId)
        .maybeSingle();
    return response != null;
  }

  // 4. 좋아요 토글 (Toggle)
  Future<bool> toggleSongLike(int songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final isLiked = await isSongLiked(songId);
    if (isLiked) {
      await _supabase
          .from('song_likes')
          .delete()
          .eq('user_id', userId)
          .eq('song_id', songId);
      return false; // 좋아요 취소됨
    } else {
      await _supabase.from('song_likes').insert({
        'user_id': userId,
        'song_id': songId,
      });
      return true; // 좋아요 됨
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
