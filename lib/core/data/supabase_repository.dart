import 'package:supabase_flutter/supabase_flutter.dart'; // Import 필수
import '../constants/department_enum.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCurriculums() async {
    try {
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
}