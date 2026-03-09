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
  int? _selectedCurriculumId;
  int? _selectedTeamId;

  final Map<int, String> _teamMap = {};
  final Map<int, String> _curriculumMap = {};
  bool _mapsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

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

          // 옵션 추출
          final Set<int> presentSessionIds = rawData.map((e) => e['curriculum_id'] as int).toSet();
          final Set<int> presentTeamIds = rawData.map((e) => e['team_id'] as int).toSet();

          final sessionOptions = presentSessionIds.toList();
          final teamOptions = presentTeamIds.toList();

          // 실제 필터링 진행
          final filteredRawLogs = rawData.where((json) {
            final curriculumId = json['curriculum_id'] as int;
            final teamId = json['team_id'] as int;
            final matchSession = _selectedCurriculumId == null || curriculumId == _selectedCurriculumId;
            final matchTeam = _selectedTeamId == null || teamId == _selectedTeamId;
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
                      "총 ${filteredRawLogs.length}명 출석",
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
                child: filteredRawLogs.isEmpty
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
                  itemCount: filteredRawLogs.length,
                  itemBuilder: (context, index) {
                    final json = filteredRawLogs[index];
                    final log = AttendanceLog.fromJson(json);

                    // DB에서 추가한 fine 값을 가져옵니다. 없으면 0원 처리.
                    final int fineAmount = json['fine'] as int? ?? 0;

                    final timeStr = DateFormat('HH:mm').format(log.createdAt.toLocal());
                    final sessionName = _curriculumMap[log.curriculumId] ?? '알 수 없는 세션';
                    final teamName = _teamMap[log.teamId] ?? '알 수 없는 팀';

                    return _buildAttendanceCard(log.userId, sessionName, teamName, timeStr, fineAmount);
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

  Widget _buildAttendanceCard(String userId, String sessionName, String teamName, String timeStr, int fineAmount) {
    final bool isLate = fineAmount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            '$sessionName • $timeStr 출석',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isLate) ...[
              const Text(
                '지각',
                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${NumberFormat('#,###').format(fineAmount)}원',
                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
              const SizedBox(height: 2),
              const Text('정상', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
            ]
          ],
        ),
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