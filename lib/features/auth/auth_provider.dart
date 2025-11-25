import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class AuthController extends StateNotifier<bool> {
  final Ref ref;

  AuthController(this.ref) : super(false);

  // 로그인 시뮬레이션 (실제로는 Supabase Auth 연결)
  Future<void> login(Department dept) async {
    // 1. 전역 상태 업데이트: 선택한 부서로 테마 변경
    ref.read(currentDeptProvider.notifier).state = dept;

    // 2. 관리자 권한 부여 (테스트용: Business팀은 관리자)
    ref.read(isManagerProvider.notifier).state = (dept == Department.business);

    state = true; // 로그인 성공 상태
  }

  void logout() {
    state = false;
  }
}

final authProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref);
});