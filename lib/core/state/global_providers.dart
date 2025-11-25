import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/department_enum.dart';

// 현재 로그인한(또는 선택한) 부서 상태
class CurrentDeptNotifier extends Notifier<Department> {
  @override
  Department build() => Department.business; // 초기값

  void setDept(Department dept) {
    state = dept;
  }
}

final currentDeptProvider = NotifierProvider<CurrentDeptNotifier, Department>(CurrentDeptNotifier.new);

// 현재 사용자가 임원진(Manager)인지 여부
class IsManagerNotifier extends Notifier<bool> {
  @override
  bool build() => false; // 초기값

  void setManager(bool isManager) {
    state = isManager;
  }
}

final isManagerProvider = NotifierProvider<IsManagerNotifier, bool>(IsManagerNotifier.new);