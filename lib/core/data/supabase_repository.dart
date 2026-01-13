import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

class SupabaseRepository {
  // 클래스 내부에서 사용하는 Supabase 클라이언트 인스턴스 이름은 '_client'입니다.
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  // ==========================================================
  // [Auth & Profile]
  // ==========================================================

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

  Future<Map<String, dynamic>?> requestTemporaryPassword({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _client.rpc('reset_password_with_verification', params: {
        'p_email': email,
        'p_name': name,
        'p_phone': phone,
      });
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint("Temp Password Error: $e");
      return null;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) return '로그인이 필요합니다.';

      final authResponse = await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      if (authResponse.user == null) {
        return '기존 비밀번호가 일치하지 않습니다.';
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await _client.from('users').update({'is_temp_password': false}).eq('id', user.id);

      return null;
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        return '기존 비밀번호가 올바르지 않습니다.';
      }
      return '비밀번호 변경 중 오류가 발생했습니다.';
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

  // ----------------------------------------------------------
  // [계정 탈퇴 기능] (수정됨: _supabase -> _client)
  // ----------------------------------------------------------
  Future<void> deleteAccount() async {
    try {
      // Supabase SQL Editor에서 만든 'delete_account' 함수 호출
      await _client.rpc('delete_account');
    } catch (e) {
      throw Exception('계정 삭제 실패: $e');
    }
  }

  // ==========================================================
  // [공식 일정] Curriculums
  // ==========================================================

  Stream<List<Map<String, dynamic>>> getCurriculumsStream(int teamId) {
    return _client
        .from('curriculums')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId)
        .order('event_date', ascending: true);
  }

  Future<bool> addCurriculum({
    required String title,
    required String description,
    required DateTime date,
    required int weekNumber,
    int? teamId,
  }) async {
    try {
      await _client.from('curriculums').insert({
        'title': title,
        'description': description,
        'week_number': weekNumber,
        'team_id': teamId ?? 1,
        'event_date': date.toIso8601String(),
        'semester_id': 1,
      });
      return true;
    } catch (e) {
      debugPrint("Add Curriculum Error: $e");
      return false;
    }
  }

  Future<List<String>> getSessionOptions() async {
    try {
      final response = await _client
          .from('curriculums')
          .select('title')
          .order('event_date', ascending: false)
          .limit(20);

      final List<dynamic> data = response;
      return data.map((e) => e['title'] as String).toSet().toList();
    } catch (e) {
      debugPrint("Error fetching sessions: $e");
      return [];
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

  // ==========================================================
  // [개인 일정] Personal Schedules
  // ==========================================================

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

  // ==========================================================
  // [Notices]
  // ==========================================================

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

  // ==========================================================
  // [Archives] 로컬 저장 + 삭제 기능
  // ==========================================================

  Future<List<Map<String, dynamic>>> fetchMyArchives() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _client
          .from('archives')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Archive Fetch Error: $e");
      return [];
    }
  }

  Future<void> saveArchiveLocally({
    required String title,
    required String description,
    required File file,
    required String fileName,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final savePath = '${directory.path}/$uniqueFileName';

      await file.copy(savePath);

      final fileExtension = fileName.split('.').last;
      await _client.from('archives').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'file_path': uniqueFileName,
        'file_type': fileExtension,
      });
    } catch (e) {
      throw Exception('저장 실패: $e');
    }
  }

  Future<void> deleteArchive(int id, String fileName) async {
    try {
      await _client.from('archives').delete().eq('id', id);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      throw Exception('삭제 실패: $e');
    }
  }

  // ==========================================================
  // [Music Social Features] 핵심 수정 부분
  // ==========================================================

  Future<void> addComment(int songId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    await _client.from('comments').insert({
      'song_id': songId,
      'user_id': user.id,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> fetchComments(int songId) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, users(name, cohort)')
          .eq('song_id', songId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteComment(int commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  // [중요 수정] 디버깅 로그 강화 및 URL 생성 로직 안정화
  Future<List<MediaItem>> fetchSongs() async {
    try {
      print('🎵 [Supabase] 노래 목록 Fetch 시작...');

      // 1. Supabase 'songs' 테이블 쿼리
      final List<dynamic> response = await _client
          .from('songs')
          .select('*')
          .order('created_at', ascending: false);

      print('🎵 [Supabase] 서버에서 응답 받음: ${response.length}개의 데이터');

      if (response.isEmpty) {
        print('⚠️ [Supabase] 데이터가 0개입니다. (테이블이 비어있거나, Row Level Security 정책 문제일 수 있음)');
        return [];
      }

      final songs = response.map((song) {
        final String rawPath = song['file_path'] ?? '';
        final String rawCover = song['cover_url'] ?? '';

        String audioUrl = rawPath;
        if (rawPath.isNotEmpty && !rawPath.startsWith('http')) {
          audioUrl = _client.storage.from('songs').getPublicUrl(rawPath);
        }

        String coverUrl = rawCover;
        if (rawCover.isNotEmpty && !rawCover.startsWith('http')) {
          coverUrl = _client.storage.from('songs').getPublicUrl(rawCover);
        }

        print('▶️ [Song] 제목: ${song['title']} | URL: $audioUrl');

        return MediaItem(
          id: song['id'].toString(),
          album: "Kraft Music",
          title: song['title'] ?? '제목 없음',
          artist: song['artist'] ?? '아티스트 미상',
          artUri: coverUrl.isNotEmpty ? Uri.tryParse(coverUrl) : null,
          extras: {'url': audioUrl}, // 여기서 변환된 전체 URL을 넘깁니다.
        );
      }).toList();

      return songs;

    } catch (e) {
      print("❌ [Supabase Error] 노래 목록 가져오기 대실패: $e");
      // 에러가 나면 빈 리스트를 반환하여 앱이 죽지 않게 함
      return [];
    }
  }

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

  Future<int> getSongLikeCount(int songId) async {
    try {
      final count = await _client
          .from('song_likes')
          .count(CountOption.exact)
          .eq('song_id', songId);
      return count;
    } catch (e) {
      return 0;
    }
  }

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

  // ==========================================================
  // [Team Members & Attendance]
  // ==========================================================

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

  Future<bool> uploadAssignment(int curriculumId) async { return false; }

  Future<void> markAttendance({
    required String sessionName,
    required String teamName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 상태가 아닙니다.');
    }

    try {
      await _client.from('attendance').insert({
        'user_id': user.id,
        'session_name': sessionName,
        'team_name': teamName,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('이미 출석 처리된 세션입니다.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTracks(int teamId) async { return []; }
}