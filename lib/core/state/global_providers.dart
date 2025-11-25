import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/department_enum.dart';

// 1. 부서 상태 관리 (StateProvider 대체)
class CurrentDeptNotifier extends Notifier<Department> {
  @override
  Department build() => Department.business; // 초기값

  void setDept(Department dept) {
    state = dept;
  }
}

final currentDeptProvider = NotifierProvider<CurrentDeptNotifier, Department>(CurrentDeptNotifier.new);

// 2. 관리자 여부 상태 관리 (StateProvider 대체)
class IsManagerNotifier extends Notifier<bool> {
  @override
  bool build() => false; // 초기값

  void setManager(bool isManager) {
    state = isManager;
  }
}

final isManagerProvider = NotifierProvider<IsManagerNotifier, bool>(IsManagerNotifier.new);