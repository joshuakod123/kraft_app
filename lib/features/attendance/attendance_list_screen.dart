import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'attendance_log_model.dart'; // 모델 파일 경로 확인

class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [수정] attendance 테이블을 직접 구독
    // (참고: Supabase 대시보드에서 attendance 테이블의 Realtime을 켜야 함)
    final stream = Supabase.instance.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('📋 실시간 출석 명단')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          // 1. 에러 발생 시 (RLS 정책 문제 등)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '데이터를 불러올 수 없습니다.\n에러: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // 2. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. 데이터 없음
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '아직 출석한 인원이 없습니다.\n(서버에 데이터가 있다면 RLS 정책을 확인하세요)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
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
                    // [수정] 비동기 함수로 이름 이니셜 로딩
                    child: _UserNameLabel(userId: log.userId, onlyInitial: true),
                  ),
                  title: Row(
                    children: [
                      // [수정] 비동기 함수로 전체 이름 로딩
                      _UserNameLabel(userId: log.userId),
                      const SizedBox(width: 8),
                      Text('(${log.teamName})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  subtitle: Text('출석: $timeStr | 세션: ${log.sessionName}'),
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

// [추가] 사용자 이름을 비동기로 가져오는 위젯 (Type Error 해결됨)
class _UserNameLabel extends StatelessWidget {
  final String userId;
  final bool onlyInitial;

  const _UserNameLabel({required this.userId, this.onlyInitial = false});

  // [핵심 수정] 쿼리 빌더 결과를 await하여 Future<Map?>으로 명확히 반환
  Future<Map<String, dynamic>?> _fetchUserName() async {
    return await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserName(), // Future를 리턴하는 함수 호출
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(onlyInitial ? '...' : 'Loading...', style: const TextStyle(color: Colors.grey));
        }

        final name = snapshot.data?['name'] as String? ?? '알 수 없음';

        if (onlyInitial) {
          return Text(name.isNotEmpty ? name[0] : '?');
        }
        return Text(name, style: const TextStyle(fontWeight: FontWeight.bold));
      },
    );
  }
}