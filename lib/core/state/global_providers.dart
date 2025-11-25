import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/department_enum.dart';

// 부서 상태
class CurrentDeptNotifier extends Notifier<Department> {
  @override
  Department build() => Department.business;

  void setDept(Department dept) => state = dept;
}

final currentDeptProvider = NotifierProvider<CurrentDeptNotifier, Department>(CurrentDeptNotifier.new);

// 관리자 여부 상태
class IsManagerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setManager(bool isManager) => state = isManager;
}

final isManagerProvider = NotifierProvider<IsManagerNotifier, bool>(IsManagerNotifier.new);