import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Auth & User ---
  User? get currentUser => _client.auth.currentUser;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null; // 성공 시 에러 없음
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
  }Future<bool> updateUserProfile({
    required String name,
    required String studentId,
    required String major,
    required String phone,
    required int teamId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // upsert: 있으면 수정, 없으면 생성
      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': name,
        'student_id': studentId,
        'major': major,
        'phone': phone,
        'team_id': teamId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      return false;
    }
  }

  // --- Curriculum ---
  Future<List<Map<String, dynamic>>> getCurriculums() async {
    try {
      final response = await _client
          .from('curriculums')
          .select()
          .order('week_number', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Curriculum Fetch Error: $e');
      return [];
    }
  }

  // --- Assignment Upload ---
  Future<bool> uploadAssignment(int curriculumId) async {
    try {
      // 1. 파일 선택
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'zip', 'jpg', 'png'],
      );

      if (result == null) return false; // 취소함

      final fileBytes = result.files.first.bytes; // Web용
      final filePath = result.files.first.path;   // Mobile용
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';

      // 2. Storage 업로드
      if (kIsWeb) {
        await _client.storage.from('assignments').uploadBinary(fileName, fileBytes!);
      } else {
        await _client.storage.from('assignments').upload(fileName, File(filePath!));
      }

      final publicUrl = _client.storage.from('assignments').getPublicUrl(fileName);

      // 3. DB Insert
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

  // --- Attendance (QR) ---
  Future<bool> markAttendance(String qrData) async {
    // QR 데이터 형식 검증 (예: "KRAFT_ATTENDANCE_2025...")
    if (!qrData.startsWith("KRAFT_ATTENDANCE")) return false;

    try {
      // 현재 주차 계산 로직이 필요하지만, 편의상 1주차로 하드코딩하거나
      // QR 데이터에 주차 정보를 넣어서 파싱하는 것이 좋습니다.
      // 여기서는 DB에 insert만 수행합니다.
      await _client.from('attendances').insert({
        'user_id': _client.auth.currentUser!.id,
        'week_number': 1, // 실제 로직에선 동적으로 변경 필요
        'check_in_time': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Attendance Error: $e");
      return false;
    }
  }

  // --- Streaming ---
  Future<List<Map<String, dynamic>>> getTracks(int teamId) async {
    try {
      final response = await _client
          .from('tracks')
          .select()
          .eq('team_id', teamId) // 내 부서 음악만 듣기 (옵션)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Tracks Fetch Error: $e');
      return [];
    }
  }

  // --- Notices ---
  Future<List<Map<String, dynamic>>> getNotices(int teamId) async {
    try {
      final response = await _client
          .from('notices')
          .select()
          .eq('team_id', teamId)
          .order('created_at', ascending: false)
          .limit(1); // 최신 1개만
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}