import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'attendance_log_model.dart'; // 위에서 만든 모델 임포트

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 뷰(View)에서 실시간 데이터 가져오기
    final stream = Supabase.instance.client
        .from('user_attendance_view')
        .stream(primaryKey: ['attendance_id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('📋 실시간 출석 명단')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('아직 출석한 인원이 없습니다.'));
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final log = AttendanceLog.fromJson(data[index]);
              final timeStr = DateFormat('HH:mm').format(log.createdAt.toLocal());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(log.userName.isNotEmpty ? log.userName[0] : '?'),
                  ),
                  title: Text('${log.userName} (${log.teamName})'),
                  subtitle: Text('출석: $timeStr | 세션: ${log.sessionId}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}