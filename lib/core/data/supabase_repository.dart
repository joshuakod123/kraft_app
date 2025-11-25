import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/department_enum.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. 커리큘럼 리스트 가져오기
  Future<List<Map<String, dynamic>>> getCurriculums() async {
    try {
      // 현재 활성화된 학기의 커리큘럼만 가져오거나 전체를 가져옴
      final response = await _client
          .from('curriculums')
          .select()
          .order('week_number', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase Fetch Error: $e');
      return [];
    }
  }

  // 2. 과제 제출하기
  Future<void> submitAssignment({
    required int curriculumId,
    required String contentUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('assignments').insert({
      'curriculum_id': curriculumId,
      'user_id': userId,
      'content_url': contentUrl,
      'status': 'pending',
    });
  }

  // 3. 사용자 정보 저장 (회원가입/로그인 직후)
  Future<void> syncUser(Department dept) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // users 테이블에 정보가 없으면 생성, 있으면 업데이트
    await _client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'team_id': dept.id,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}