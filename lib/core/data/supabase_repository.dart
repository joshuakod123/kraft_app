import 'dart:io';
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
  Future<bool> updateUserProfile({required String name, required String major, required String phone, required int teamId}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      await _client.from('users').upsert({
        'id': user.id, 'email': user.email, 'name': name,
        'major': major, 'phone': phone, 'team_id': teamId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) { return false; }
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

  // --- [수정] Curriculum (공식 일정) ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    // [중요] .order() 제거 (스트림 에러 방지)
    return _client
        .from('curriculums')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId);
  }

  Future<bool> addCurriculum(String title, String desc, DateTime date, int teamId) async {
    try {
      await _client.from('curriculums').insert({
        'title': title,
        'description': desc,
        'week_number': 0,
        'team_id': teamId,
        'event_date': date.toIso8601String(),
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

  // --- [수정] Personal Schedules (개인 일정) ---
  Stream<List<Map<String, dynamic>>> getPersonalSchedulesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // [중요] .order() 제거
    return _client
        .from('personal_schedules')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  Future<bool> addPersonalSchedule(String title, String desc, DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      await _client.from('personal_schedules').insert({
        'user_id': userId,
        'title': title,
        'description': desc,
        'event_date': date.toIso8601String(),
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

  // --- Others ---
  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client.from('assignments').select('*, curriculums(title)').eq('user_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }
  Future<bool> uploadAssignment(int curriculumId) async { return false; }
  Future<bool> markAttendance(String qrData) async { return true; }
  Future<List<Map<String, dynamic>>> getTracks(int teamId) async { return []; }
}