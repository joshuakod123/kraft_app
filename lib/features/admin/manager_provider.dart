import 'package:flutter_riverpod/flutter_riverpod.dart';

// [수정] void 상태 관리
class ManagerNotifier extends Notifier<void> {
  @override
  void build() {
  }

  Future<void> approveAssignment(String assignmentId) async {
    print("Assignment $assignmentId Approved!");
  }
}

final managerProvider = NotifierProvider<ManagerNotifier, void>(ManagerNotifier.new);