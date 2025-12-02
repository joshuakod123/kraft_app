import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;

  // --- Auth ---
  Future<String?> signIn({required String email, required String password}) async {
    try { await _client.auth.signInWithPassword(email: email, password: password); return null; } catch (e) { return e.toString(); }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try { await _client.auth.signUp(email: email, password: password); return null; } catch (e) { return e.toString(); }
  }

  // --- Profile ---
  Future<bool> updateUserProfile({
    required String name,
    required String major,
    required String phone,
    required int teamId,
    String? school,
    String? studentId,
    int? age,
    String? gender,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': name,
        'major': major,
        'phone': phone,
        'team_id': teamId,
        'school': school,
        'student_id': studentId,
        'age': age,
        'gender': gender,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      return await _client.from('users').select().eq('id', userId).maybeSingle();
    } catch (e) { return null; }
  }

  // --- Attendance (테이블 없어도 0 리턴하도록 처리) ---
  Future<Map<String, int>> getAttendanceStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'attended': 0, 'total': 16};

      final response = await _client
          .from('attendance')
          .select('*', CountOption.exact)
          .eq('user_id', userId);

      final count = response.count;
      return {'attended': count, 'total': 16};
    } catch (e) {
      debugPrint("Attendance Error (Check DB Table): $e");
      return {'attended': 0, 'total': 16};
    }
  }

  // --- Streaming Community ---
  Future<bool> toggleSongLike(int songId) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final existing = await _client.from('song_likes').select().eq('user_id', userId).eq('song_id', songId).maybeSingle();

      if (existing != null) {
        await _client.from('song_likes').delete().eq('id', existing['id']);
        return false;
      } else {
        await _client.from('song_likes').insert({'user_id': userId, 'song_id': songId});
        return true;
      }
    } catch (e) { return false; }
  }

  // 실시간 좋아요 상태 확인
  Stream<Map<String, dynamic>> getSongLikeStatus(int songId) {
    return Stream.fromFuture(Future(() async {
      try {
        final userId = _client.auth.currentUser?.id;
        final countRes = await _client.from('song_likes').select('*', CountOption.exact).eq('song_id', songId);
        final count = countRes.count;

        bool isLiked = false;
        if (userId != null) {
          final myLike = await _client.from('song_likes').select().eq('user_id', userId).eq('song_id', songId).maybeSingle();
          isLiked = myLike != null;
        }
        return {'count': count, 'isLiked': isLiked};
      } catch (e) {
        return {'count': 0, 'isLiked': false};
      }
    }));
  }

  Future<void> addSongComment(int songId, String content) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('song_comments').insert({'user_id': userId, 'song_id': songId, 'content': content});
    } catch (e) { debugPrint("Comment Error: $e"); }
  }

  Stream<List<Map<String, dynamic>>> getSongComments(int songId) {
    return _client.from('song_comments').stream(primaryKey: ['id']).eq('song_id', songId).order('created_at', ascending: false).asyncMap((comments) async {
      List<Map<String, dynamic>> result = [];
      for (var c in comments) {
        final user = await _client.from('users').select('name').eq('id', c['user_id']).maybeSingle();
        result.add({...c, 'user': user});
      }
      return result;
    });
  }

  // --- Curriculums & Archive (기존 코드 유지) ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client.from('curriculums').stream(primaryKey: ['id']).eq('team_id', teamId).order('event_date', ascending: true);
  }
  Future<bool> addCurriculum(String title, String desc, DateTime date, DateTime? endTime, int teamId) async {
    try {
      await _client.from('curriculums').insert({
        'title': title, 'description': desc, 'team_id': teamId,
        'event_date': date.toIso8601String(), 'end_time': endTime?.toIso8601String(), 'semester_id': 1
      });
      return true;
    } catch (e) { return false; }
  }
  Future<bool> deleteCurriculum(int id) async {
    try { await _client.from('curriculums').delete().eq('id', id); return true; } catch (e) { return false; }
  }
  Stream<List<Map<String, dynamic>>> getPersonalSchedulesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client.from('personal_schedules').stream(primaryKey: ['id']).eq('user_id', userId).order('event_date', ascending: true);
  }
  Future<bool> addPersonalSchedule(String title, String desc, DateTime date, DateTime? endTime) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      await _client.from('personal_schedules').insert({
        'user_id': userId, 'title': title, 'description': desc,
        'event_date': date.toIso8601String(), 'end_time': endTime?.toIso8601String()
      });
      return true;
    } catch (e) { return false; }
  }
  Future<bool> deletePersonalSchedule(int id) async {
    try { await _client.from('personal_schedules').delete().eq('id', id); return true; } catch (e) { return false; }
  }
  Stream<List<Map<String, dynamic>>> getNoticesStream(int teamId) {
    return _client.from('notices').stream(primaryKey: ['id']).eq('team_id', teamId).order('created_at', ascending: false);
  }
  Future<bool> addNotice(String title, String content, int teamId) async {
    try { await _client.from('notices').insert({'title': title, 'content': content, 'team_id': teamId}); return true; } catch (e) { return false; }
  }
  Future<bool> deleteNotice(int id) async {
    try { await _client.from('notices').delete().eq('id', id); return true; } catch (e) { return false; }
  }
  Stream<List<Map<String, dynamic>>> getMyArchivesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client.from('archives').stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', ascending: false);
  }
  Future<void> addArchive(String title, String description, String fileUrl) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('archives').insert({'user_id': userId, 'title': title, 'description': description, 'file_url': fileUrl});
    } catch (e) {}
  }
  Future<bool> uploadAssignment(int curriculumId) async { return false; }
  Future<bool> markAttendance(String userId, String sessionId) async { return true; }
}