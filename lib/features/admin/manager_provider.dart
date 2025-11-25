import 'package:flutter_riverpod/flutter_riverpod.dart';

// 관리자 전용 기능 (승인 등) 로직
class ManagerController extends Notifier<void> {
  @override
  void build() {
    // 초기 상태 없음
  }

  Future<void> approveAssignment(String assignmentId) async {
    // Supabase Update Logic
    // await supabase.from('assignments').update({'status': 'approved'}).eq('id', assignmentId);
    print("Assignment $assignmentId Approved!");
  }
}

final managerProvider = NotifierProvider<ManagerController, void>(ManagerController.new);