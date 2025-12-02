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
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      return await _client.from('users').select().eq('id', userId).maybeSingle();
    } catch (e) { return null; }
  }

  // --- Attendance ---
  Future<Map<String, int>> getAttendanceStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'attended': 0, 'total': 16};
      final count = await _client.from('attendance').count(CountOption.exact).eq('user_id', userId);
      return {'attended': count, 'total': 16};
    } catch (e) { return {'attended': 0, 'total': 16}; }
  }

  Future<bool> markAttendance(String sessionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      final check = await _client.from('attendance').select().eq('user_id', userId).eq('session_id', sessionId).maybeSingle();
      if (check != null) return true;
      await _client.from('attendance').insert({'user_id': userId, 'session_id': sessionId});
      return true;
    } catch (e) { return false; }
  }

  // --- Streaming (Likes Only) ---
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

  Stream<Map<String, dynamic>> getSongLikeStatus(int songId) {
    return Stream.fromFuture(Future(() async {
      try {
        final userId = _client.auth.currentUser?.id;
        final count = await _client.from('song_likes').count(CountOption.exact).eq('song_id', songId);
        bool isLiked = false;
        if (userId != null) {
          final myLike = await _client.from('song_likes').select().eq('user_id', userId).eq('song_id', songId).maybeSingle();
          isLiked = myLike != null;
        }
        return {'count': count, 'isLiked': isLiked};
      } catch (e) { return {'count': 0, 'isLiked': false}; }
    }));
  }

  // --- [New] Community (게시판) ---
  Future<void> addCommunityPost(String content, String category) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('community_posts').insert({
        'user_id': userId,
        'content': content,
        'category': category, // 'FREE', 'REVIEW' 등
      });
    } catch (e) { debugPrint("Post Error: $e"); }
  }

  Stream<List<Map<String, dynamic>>> getCommunityPosts() {
    return _client.from('community_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((posts) async {
      List<Map<String, dynamic>> result = [];
      for (var p in posts) {
        final user = await _client.from('users').select('name, team_id').eq('id', p['user_id']).maybeSingle();
        result.add({...p, 'user': user});
      }
      return result;
    });
  }

  // --- Others ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client.from('curriculums').stream(primaryKey: ['id']).eq('team_id', teamId).order('event_date', ascending: true);
  }
  Future<bool> addCurriculum(String t, String d, DateTime date, DateTime? end, int tid) async {
    try { await _client.from('curriculums').insert({'title': t, 'description': d, 'team_id': tid, 'event_date': date.toIso8601String(), 'end_time': end?.toIso8601String(), 'semester_id': 1}); return true; } catch (e) { return false; }
  }
  Future<bool> deleteCurriculum(int id) async { try { await _client.from('curriculums').delete().eq('id', id); return true; } catch (e) { return false; } }
  Stream<List<Map<String, dynamic>>> getPersonalSchedulesStream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client.from('personal_schedules').stream(primaryKey: ['id']).eq('user_id', uid).order('event_date', ascending: true);
  }
  Future<bool> addPersonalSchedule(String t, String d, DateTime date, DateTime? end) async {
    try { await _client.from('personal_schedules').insert({'user_id': _client.auth.currentUser!.id, 'title': t, 'description': d, 'event_date': date.toIso8601String(), 'end_time': end?.toIso8601String()}); return true; } catch (e) { return false; }
  }
  Future<bool> deletePersonalSchedule(int id) async { try { await _client.from('personal_schedules').delete().eq('id', id); return true; } catch (e) { return false; } }
  Stream<List<Map<String, dynamic>>> getNoticesStream(int teamId) { return _client.from('notices').stream(primaryKey: ['id']).eq('team_id', teamId); }
  Future<bool> addNotice(String t, String c, int tid) async { try { await _client.from('notices').insert({'title': t, 'content': c, 'team_id': tid}); return true; } catch (e) { return false; } }
  Future<bool> deleteNotice(int id) async { try { await _client.from('notices').delete().eq('id', id); return true; } catch (e) { return false; } }
  Stream<List<Map<String, dynamic>>> getMyArchivesStream() { return const Stream.empty(); }
  Future<void> addArchive(String t, String d, String u) async {}
  Future<bool> uploadAssignment(int id) async { return false; }
}