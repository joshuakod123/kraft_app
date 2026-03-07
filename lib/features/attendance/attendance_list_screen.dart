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
  // 필터 상태 (ID 기준)
  int? _selectedCurriculumId;
  int? _selectedTeamId;

  // 이름 매핑을 위한 메모리 캐시
  final Map<int, String> _teamMap = {};
  final Map<int, String> _curriculumMap = {};
  bool _mapsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  // 화면 진입 시 부서/세션 이름을 미리 한 번만 불러옵니다.
  Future<void> _loadMaps() async {
    final client = Supabase.instance.client;
    final teamsData = await client.from('teams').select('id, name');
    final curriculumsData = await client.from('curriculums').select('id, title');

    if (mounted) {
      setState(() {
        for (var t in teamsData) {
          _teamMap[t['id'] as int] = t['name'] as String;
        }
        for (var c in curriculumsData) {
          _curriculumMap[c['id'] as int] = c['title'] as String;
        }
        _mapsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapsLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    final stream = Supabase.instance.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('📋 실시간 출석 현황', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('데이터 로딩 실패\n${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data ?? [];
          final allLogs = rawData.map((json) => AttendanceLog.fromJson(json)).toList();

          // 필터 옵션 추출 (기록이 있는 ID만 모음)
          final Set<int> presentSessionIds = allLogs.map((e) => e.curriculumId).toSet();
          final Set<int> presentTeamIds = allLogs.map((e) => e.teamId).toSet();

          final sessionOptions = presentSessionIds.toList();
          final teamOptions = presentTeamIds.toList();

          // 실제 필터링 진행
          final filteredLogs = allLogs.where((log) {
            final matchSession = _selectedCurriculumId == null || log.curriculumId == _selectedCurriculumId;
            final matchTeam = _selectedTeamId == null || log.teamId == _selectedTeamId;
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
                    // (1) 세션 선택
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: presentSessionIds.contains(_selectedCurriculumId) ? _selectedCurriculumId : null,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.orangeAccent),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('전체 세션')),
                                ...sessionOptions.map((id) {
                                  return DropdownMenuItem<int?>(
                                    value: id,
                                    child: Text(_curriculumMap[id] ?? '알 수 없는 세션'),
                                  );
                                }),
                              ],
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCurriculumId = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // (2) 부서 선택
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('전체', isSelected: _selectedTeamId == null, onSelected: () => setState(() => _selectedTeamId = null)),
                          ...teamOptions.map((id) {
                            return _buildFilterChip(
                              _teamMap[id] ?? '알 수 없음',
                              isSelected: _selectedTeamId == id,
                              onSelected: () => setState(() => _selectedTeamId = id),
                            );
                          }),
                        ],
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
                    if (_selectedCurriculumId != null)
                      Text(
                        _curriculumMap[_selectedCurriculumId!] ?? '',
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
                    final sessionName = _curriculumMap[log.curriculumId] ?? '알 수 없는 세션';
                    final teamName = _teamMap[log.teamId] ?? '알 수 없는 팀';

                    return _buildAttendanceCard(log.userId, sessionName, teamName, timeStr);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected, required VoidCallback onSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
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
  }

  Widget _buildAttendanceCard(String userId, String sessionName, String teamName, String timeStr) {
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
          child: _UserNameLabel(userId: userId, onlyInitial: true),
        ),
        title: Row(
          children: [
            _UserNameLabel(userId: userId),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                teamName,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$sessionName • $timeStr 출석',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
      ),
    );
  }
}

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