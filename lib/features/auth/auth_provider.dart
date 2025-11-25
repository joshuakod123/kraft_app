import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> login(Department dept) async {
    ref.read(currentDeptProvider.notifier).setDept(dept);
    ref.read(isManagerProvider.notifier).setManager(dept == Department.business);
    state = true;
  }

  void logout() {
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);