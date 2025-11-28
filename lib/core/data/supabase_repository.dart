import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

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
      final data = await _client.from('users').select().eq('id', userId).maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Profile Fetch Error: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String name,
    // studentId 제거됨
    required String major,
    required String phone,
    required int teamId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      debugPrint("🚀 Updating profile for: ${user.id}");

      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': name,
        // student_id 컬럼 제외
        'major': major,
        'phone': phone,
        'team_id': teamId,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ Profile update successful!");
      return true;
    } catch (e) {
      debugPrint("❌ Profile Update Error: $e");
      return false;
    }
  }

  // --- 기존 기능들 ---
  Future<List<Map<String, dynamic>>> getCurriculums() async {
    try {
      final response = await _client.from('curriculums').select().order('week_number', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client
          .from('assignments')
          .select('*, curriculums(title, week_number)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<bool> uploadAssignment(int curriculumId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'zip', 'jpg', 'png'],
      );
      if (result == null) return false;

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';

      if (kIsWeb) {
        await _client.storage.from('assignments').uploadBinary(fileName, fileBytes!);
      } else {
        await _client.storage.from('assignments').upload(fileName, File(filePath!));
      }

      final publicUrl = _client.storage.from('assignments').getPublicUrl(fileName);

      await _client.from('assignments').insert({
        'curriculum_id': curriculumId,
        'user_id': _client.auth.currentUser!.id,
        'content_url': publicUrl,
        'status': 'submitted',
      });
      return true;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return false;
    }
  }

  Future<bool> markAttendance(String qrData) async { return true; }
  Future<List<Map<String, dynamic>>> getNotices(int teamId) async {
    try {
      final response = await _client.from('notices').select().eq('team_id', teamId).order('created_at', ascending: false).limit(1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }
  Future<List<Map<String, dynamic>>> getTracks(int teamId) async { return []; }
}