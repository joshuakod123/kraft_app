import 'package:flutter/foundation.dart'; // debugPrint용
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerNotifier extends Notifier<void> {
  @override
  void build() {
  }

  Future<void> approveAssignment(String assignmentId) async {
    // [수정] print -> debugPrint
    debugPrint("Assignment $assignmentId Approved!");
  }
}

final managerProvider = NotifierProvider<ManagerNotifier, void>(ManagerNotifier.new);