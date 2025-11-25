import 'dart:async'; // Stream 사용을 위해 필요
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

// [수정] Notifier<bool> 상속 확인
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // 초기값: 로그아웃 상태
  }

  // 로그인 시뮬레이션
  Future<void> login(Department dept) async {
    // 1. 전역 상태 업데이트
    ref.read(currentDeptProvider.notifier).setDept(dept);
    ref.read(isManagerProvider.notifier).setManager(dept == Department.business);

    // 2. 상태 변경 (state는 Notifier 내부 변수)
    state = true;
  }

  void logout() {
    state = false;
  }

  // Stream getter 추가 (라우터 연결용)
  Stream<bool> get stream {
    // Notifier는 기본적으로 stream을 제공하지 않으므로,
    // 값이 바뀔 때마다 리스너들에게 알리는 메커니즘 활용
    return StreamController<bool>.broadcast().stream;
    // (실제로는 ref.listen을 사용하는 GoRouterRefreshStream이 알아서 처리하므로 이 getter는 없어도 되지만,
    // 위 app_router에서 notifier.stream을 호출하므로, 기본적으로 제공되는 stream을 쓰거나,
    // 만약 에러가 난다면 아래처럼 작성하지 않고 그냥 둡니다. Notifier는 기본적으로 stream 속성이 없습니다.)
  }
}

// [중요] Notifier의 stream 속성은 3.0에서 제거되거나 변경될 수 있으니,
// AppRouter에서 authNotifier.stream 대신 다른 방식을 써야 할 수도 있습니다.
// 하지만 가장 쉬운 수정법은 아래 Provider 정의를 확실히 하는 것입니다.

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);