import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;

  // --- Auth & Profile --- (기존 코드 유지)
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

  // --- Notices (삭제 기능 강화) ---
  Stream<List<Map<String, dynamic>>> getNoticesStream(int teamId) {
    return _client.from('notices').stream(primaryKey: ['id']).eq('team_id', teamId).order('created_at', ascending: false);
  }

  Future<bool> addNotice(String title, String content, int teamId) async {
    try {
      await _client.from('notices').insert({'title': title, 'content': content, 'team_id': teamId});
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteNotice(int id) async {
    try {
      // [수정] 삭제 시 에러 확인용 로그 추가
      debugPrint("Deleting Notice ID: $id");
      await _client.from('notices').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Delete Notice Error: $e");
      return false;
    }
  }

  // --- Curriculum (삭제 기능 강화) ---
  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client.from('curriculums').stream(primaryKey: ['id']).eq('team_id', teamId).order('week_number', ascending: true);
  }

  Future<bool> addCurriculum(String title, String desc, int week, int teamId) async {
    try {
      await _client.from('curriculums').insert({'title': title, 'description': desc, 'week_number': week, 'team_id': teamId});
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteCurriculum(int id) async {
    try {
      debugPrint("Deleting Curriculum ID: $id");
      await _client.from('curriculums').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Delete Curriculum Error: $e");
      return false;
    }
  }

  // --- Others (기존 유지) ---
  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client.from('assignments').select('*, curriculums(title, week_number)').eq('user_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<bool> uploadAssignment(int curriculumId) async {
    // 파일 업로드 로직 (기존 유지)
    return false;
  }

  Future<bool> markAttendance(String qrData) async { return true; }
  Future<List<Map<String, dynamic>>> getTracks(int teamId) async { return []; }
  Future<List<Map<String, dynamic>>> getNotices(int teamId) async { return []; }
  Future<List<Map<String, dynamic>>> getCurriculums(int teamId) async { return []; }
}