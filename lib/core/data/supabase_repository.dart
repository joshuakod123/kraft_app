import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  // [중요] 이 변수(_client)를 모든 곳에서 사용해야 합니다.
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  // [New] 현재 로그인한 유저의 ID Getter
  String? get currentUserId => _client.auth.currentUser?.id;

  // --- Auth & Profile ---
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      return await _client.from('users').select('*, teams(*)').eq('id', userId).maybeSingle();
    } catch (e) {
      return null;
    }
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

      int cohort = 0;
      if (studentId.length >= 4) {
        cohort = int.tryParse(studentId.substring(2, 4)) ?? 0;
      }

      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': name,
        'major': major,
        'phone': phone,
        'team_id': teamId,
        'school': school,
        'student_id': studentId,
        'gender': gender,
        'cohort': cohort,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      return false;
    }
  }

  // [New] 임원진 여부 확인 (삭제 권한용)
  Future<bool> isAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return false;

      final role = data['role'] as String?;
      return role == 'admin' || role == 'manager' || role == 'executive';
    } catch (e) {
      return false;
    }
  }

  // --- [공식 일정] Curriculums ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client
        .from('curriculums')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId)
        .order('event_date', ascending: true);
  }

  Future<bool> addCurriculum(String title, String desc, DateTime date, DateTime? endTime, int teamId) async {
    try {
      await _client.from('curriculums').insert({
        'title': title,
        'description': desc,
        'week_number': 0,
        'team_id': teamId,
        'event_date': date.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'semester_id': 1,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCurriculum(int id) async {
    try {
      await _client.from('curriculums').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- [개인 일정] Personal Schedules ---
  Stream<List<Map<String, dynamic>>> getPersonalSchedulesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('personal_schedules')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('event_date', ascending: true);
  }

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
      return false;
    }
  }

  Future<bool> deletePersonalSchedule(int id) async {
    try {
      await _client.from('personal_schedules').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Notices ---
  Stream<List<Map<String, dynamic>>> getNoticesStream(int teamId) {
    return _client.from('notices').stream(primaryKey: ['id']).eq('team_id', teamId).order('created_at', ascending: false);
  }

  Future<bool> addNotice(String title, String content, int teamId) async {
    try {
      await _client.from('notices').insert({'title': title, 'content': content, 'team_id': teamId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotice(int id) async {
    try {
      await _client.from('notices').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Archives ---
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
        'file_type': 'image',
      });
    } catch (e) {
      debugPrint("Add Archive Error: $e");
    }
  }

  // --- [Music Social Features] ---

  // 1. 댓글 작성
  Future<void> addComment(int songId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    await _client.from('comments').insert({
      'song_id': songId,
      'user_id': user.id,
      'content': content,
    });
  }

  // 2. 댓글 가져오기 (Users 테이블 JOIN)
  Future<List<Map<String, dynamic>>> fetchComments(int songId) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, users(name, cohort)') // users 테이블의 name, cohort 필드 로드
          .eq('song_id', songId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Fetch Comments Error: $e");
      return [];
    }
  }

  // 3. 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  // 4. 좋아요 상태 확인
  Future<bool> isSongLiked(int songId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final response = await _client
          .from('song_likes')
          .select()
          .eq('user_id', userId)
          .eq('song_id', songId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // [New] 5. 좋아요 갯수 가져오기 (수정됨)
  Future<int> getSongLikeCount(int songId) async {
    try {
      // .count()는 int를 바로 반환합니다.
      final count = await _client
          .from('song_likes')
          .count(CountOption.exact)
          .eq('song_id', songId);

      return count;
    } catch (e) {
      debugPrint("Like Count Error: $e");
      return 0;
    }
  }

  // 6. 좋아요 토글
  Future<bool> toggleSongLike(int songId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final isLiked = await isSongLiked(songId);
    if (isLiked) {
      await _client
          .from('song_likes')
          .delete()
          .eq('user_id', userId)
          .eq('song_id', songId);
      return false;
    } else {
      await _client.from('song_likes').insert({
        'user_id': userId,
        'song_id': songId,
      });
      return true;
    }
  }

  // --- Team Members ---
  Future<List<Map<String, dynamic>>> getTeamMembers(int teamId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('team_id', teamId)
          .order('role', ascending: true)
          .order('name', ascending: true);

      final List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(response);
      members.sort((a, b) {
        if (a['role'] == 'manager' && b['role'] != 'manager') return -1;
        if (a['role'] != 'manager' && b['role'] == 'manager') return 1;
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });
      return members;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client
          .from('assignments')
          .select('*, curriculums(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> uploadAssignment(int curriculumId) async {
    return false;
  }

  Future<bool> markAttendance(String qrData) async {
    return true;
  }

  Future<List<Map<String, dynamic>>> getTracks(int teamId) async {
    return [];
  }
}