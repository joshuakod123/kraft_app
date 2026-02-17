import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'attendance_log_model.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  // 필터 상태 관리
  String _selectedSession = '전체';
  String _selectedTeam = '전체';

  @override
  Widget build(BuildContext context) {
    // DB의 attendance 테이블을 실시간 구독
    final stream = Supabase.instance.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 배경색 통일
      appBar: AppBar(
        title: const Text('📋 실시간 출석 현황', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          // 1. 에러 처리
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '데이터 로딩 실패\n${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 2. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data ?? [];

          // 3. 데이터 가공 (모델 변환)
          final allLogs = rawData.map((json) => AttendanceLog.fromJson(json)).toList();

          // 4. 필터 옵션 추출 (데이터에 존재하는 항목만)
          final Set<String> sessions = {'전체', ...allLogs.map((e) => e.sessionName)};
          final Set<String> teams = {'전체', ...allLogs.map((e) => e.teamName)};

          // 최신순 정렬 등을 위해 리스트로 변환
          final sessionOptions = sessions.toList()..sort(); // 가나다순 (필요시 로직 변경 가능)
          final teamOptions = teams.toList()..sort();

          // 5. 실제 필터링 로직
          final filteredLogs = allLogs.where((log) {
            final matchSession = _selectedSession == '전체' || log.sessionName == _selectedSession;
            final matchTeam = _selectedTeam == '전체' || log.teamName == _selectedTeam;
            return matchSession && matchTeam;
          }).toList();

          return Column(
            children: [
              // [상단 필터 영역]
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // (1) 세션 선택 (Dropdown)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: sessions.contains(_selectedSession) ? _selectedSession : '전체',
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.orangeAccent),
                              isExpanded: true,
                              items: sessionOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedSession = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // (2) 부서 선택 (Chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: teamOptions.map((team) {
                          final isSelected = _selectedTeam == team;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(team),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedTeam = selected ? team : '전체';
                                });
                              },
                              selectedColor: Colors.orangeAccent,
                              backgroundColor: Colors.white10,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // [중간 요약 바]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "총 ${filteredLogs.length}명 출석",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_selectedSession != '전체')
                      Text(
                        _selectedSession,
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // [리스트 영역]
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text("해당 조건의 출석 기록이 없습니다.", style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final timeStr = DateFormat('HH:mm').format(log.createdAt.toLocal());

                    return _buildAttendanceCard(log, timeStr);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceLog log, String timeStr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: _UserNameLabel(userId: log.userId, onlyInitial: true),
        ),
        title: Row(
          children: [
            _UserNameLabel(userId: log.userId),
            const SizedBox(width: 8),
            // 부서명 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.teamName,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${log.sessionName} • $timeStr 출석',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
      ),
    );
  }
}

// 사용자 이름을 비동기로 가져오는 위젯
class _UserNameLabel extends StatelessWidget {
  final String userId;
  final bool onlyInitial;

  const _UserNameLabel({required this.userId, this.onlyInitial = false});

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
      future: _fetchUserName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(onlyInitial ? '...' : '...', style: const TextStyle(color: Colors.grey));
        }

        final name = snapshot.data?['name'] as String? ?? '알 수 없음';

        if (onlyInitial) {
          return Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
        }
        return Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15));
      },
    );
  }
}