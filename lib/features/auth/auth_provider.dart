import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart'; // Repo import

class AuthNotifier extends Notifier<bool> {
  final _repo = SupabaseRepository();

  @override
  bool build() {
    // 앱 시작 시 세션 복구 시도
    _restoreSession();
    return false;
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // 세션이 있으면 유저 프로필(부서 정보) 가져오기
      final profile = await _repo.getUserProfile();
      if (profile != null) {
        final teamId = profile['team_id'] as int?;
        // teamId에 맞는 Department Enum 찾기 (기본값 Business)
        final dept = Department.values.firstWhere(
                (d) => d.id == teamId,
            orElse: () => Department.business
        );

        ref.read(currentDeptProvider.notifier).setDept(dept);
        ref.read(isManagerProvider.notifier).setManager(profile['role'] == 'manager');
        state = true; // 로그인 성공
      }
    }
  }

  Future<void> login(Department dept) async {
    // [실제 구현 시] Supabase Auth 로그인 로직 (Google/Email)이 들어갈 곳.
    // 현재는 데모용으로 익명 로그인 + 부서 선택 방식 유지

    // 1. 전역 상태 업데이트
    ref.read(currentDeptProvider.notifier).setDept(dept);
    ref.read(isManagerProvider.notifier).setManager(dept == Department.business);

    // 2. 상태 변경 -> Router 리다이렉트 트리거
    state = true;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);