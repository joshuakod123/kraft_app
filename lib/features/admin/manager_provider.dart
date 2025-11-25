import 'package:flutter_riverpod/flutter_riverpod.dart';

// 관리자 전용 기능 (승인 등) 로직
class ManagerNotifier extends Notifier<void> {
  @override
  void build() {
    // 상태 없음 (void)
  }

  Future<void> approveAssignment(String assignmentId) async {
    // 여기에 Supabase 업데이트 로직이 들어갑니다.
    // await supabase.from('assignments').update({'status': 'approved'}).eq('id', assignmentId);
    print("Assignment $assignmentId Approved!");
  }
}

final managerProvider = NotifierProvider<ManagerNotifier, void>(ManagerNotifier.new);