import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // 초기 로그인 상태 (false: 로그아웃)
  }

  // 로그인 시뮬레이션
  Future<void> login(Department dept) async {
    // 1. 전역 상태 업데이트: 선택한 부서로 테마 변경
    ref.read(currentDeptProvider.notifier).setDept(dept);

    // 2. 관리자 권한 부여 (테스트용: Business팀은 관리자)
    ref.read(isManagerProvider.notifier).setManager(dept == Department.business);

    state = true; // 로그인 성공 상태로 변경
  }

  void logout() {
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);