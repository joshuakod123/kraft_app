import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/department_enum.dart';

// 현재 로그인한(또는 선택한) 부서 상태
final currentDeptProvider = StateProvider<Department>((ref) => Department.business);

// 현재 사용자가 임원진(Manager)인지 여부
final isManagerProvider = StateProvider<bool>((ref) => false);