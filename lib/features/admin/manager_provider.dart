import 'package:flutter/foundation.dart'; // debugPrint용
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> approveAssignment(String assignmentId) async {
    // 실제 로직 구현
    debugPrint("Assignment $assignmentId Approved!"); // [수정] debugPrint 사용
  }
}

final managerProvider = NotifierProvider<ManagerNotifier, void>(ManagerNotifier.new);