import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// [Provider 및 Enum 연결]
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';

class CurriculumListScreen extends ConsumerStatefulWidget {
  const CurriculumListScreen({super.key});

  @override
  ConsumerState<CurriculumListScreen> createState() => _CurriculumListScreenState();
}

class _CurriculumListScreenState extends ConsumerState<CurriculumListScreen> {
  final _supabase = Supabase.instance.client;
  final SupabaseRepository _repository = SupabaseRepository();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 이벤트 데이터 (개인 일정 + 공식 커리큘럼 통합)
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllEvents();
    });
  }

  // --------------------------------------------------------
  // 1. 데이터 로직 (개인 + 공식 통합)
  // --------------------------------------------------------
  Future<void> _fetchAllEvents() async {
    try {
      final myDept = ref.read(currentDeptProvider);
      final myUserId = _supabase.auth.currentUser?.id;

      // 1. 개인 일정 가져오기
      final schedulesResponse = await _supabase
          .from('schedules')
          .select()
          .eq('user_id', myUserId ?? '')
          .order('start_time', ascending: true);

      // 2. 공식 커리큘럼 가져오기 (팀별 필터링 적용)
      final curriculumsResponse = await _supabase
          .from('curriculums')
          .select()
          .eq('team_id', myDept.id)
          .order('event_date', ascending: true);

      Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

      // [데이터 병합 로직]

      // A. 개인 일정 처리
      for (var item in schedulesResponse) {
        final DateTime startDate = DateTime.parse(item['start_time']).toLocal();
        final DateTime dateKey = DateTime.utc(startDate.year, startDate.month, startDate.day);

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];

        newEvents[dateKey]!.add({
          ...item,
          'type': 'personal',
          'is_official': false,
        });
      }

      // B. 공식 커리큘럼 처리
      for (var item in curriculumsResponse) {
        final DateTime eventDate = DateTime.parse(item['event_date']).toLocal();
        final DateTime dateKey = DateTime.utc(eventDate.year, eventDate.month, eventDate.day);

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];

        newEvents[dateKey]!.add({
          'id': item['id'],
          'title': item['title'],
          'description': item['description'],
          'start_time': item['event_date'],
          'end_time': item['end_time'] ?? item['event_date'],
          'type': 'official',
          'is_official': true,
          'week_number': item['week_number'],
        });
      }

      if (mounted) {
        setState(() {
          _events = newEvents;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // 개인 일정 추가
  Future<void> _addPersonalSchedule({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final myDept = ref.read(currentDeptProvider);
    try {
      await _repository.addPersonalSchedule(title, description, startTime, endTime);

      await _fetchAllEvents();
      if (mounted) _showPopup(context, "성공", "개인 일정이 추가되었습니다!", myDept.color);
    } catch (e) {
      if (mounted) _showPopup(context, "오류", "일정 추가 실패: $e", Colors.redAccent, isError: true);
    }
  }

  // [수정] 공식 커리큘럼 추가 (시간 포함)
  Future<void> _addOfficialCurriculum({
    required String title,
    required String description,
    required int weekNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final myDept = ref.read(currentDeptProvider);

      await _repository.addCurriculum(
        title: title,
        description: description,
        weekNumber: weekNumber,
        startTime: startTime, // 시작 시간
        endTime: endTime,     // 종료 시간
        teamId: myDept.id,
      );

      await _fetchAllEvents();
      if (mounted) _showPopup(context, "성공", "공식 세션이 등록되었습니다.\n${myDept.name} 팀 캘린더에 추가됩니다.", Colors.orangeAccent);
    } catch (e) {
      if (mounted) _showPopup(context, "오류", "세션 등록 실패: $e", Colors.redAccent, isError: true);
    }
  }

  Future<void> _deleteItem(int id, bool isOfficial, bool isManager) async {
    if (isOfficial && !isManager) {
      _showPopup(context, "권한 없음", "공식 일정은 임원만 삭제할 수 있습니다.", Colors.redAccent, isError: true);
      return;
    }

    try {
      if (isOfficial) {
        await _supabase.from('curriculums').delete().eq('id', id);
      } else {
        await _supabase.from('schedules').delete().eq('id', id); // schedules or personal_schedules
      }

      await _fetchAllEvents();
      if (mounted) _showPopup(context, "삭제 완료", "일정이 삭제되었습니다.", Colors.greenAccent);
    } catch (e) {
      if (mounted) _showPopup(context, "오류", "삭제 실패: $e", Colors.redAccent, isError: true);
    }
  }

  // --------------------------------------------------------
  // 2. UI 빌드
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Department currentDept = ref.watch(currentDeptProvider);
    final bool isManager = ref.watch(isManagerProvider);
    final Color themeColor = currentDept.color;
    final dailyEvents = _getEventsForDay(_selectedDay!);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "CALENDAR",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2.0,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchAllEvents,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor.withOpacity(0.25),
              const Color(0xFF121212),
              const Color(0xFF000000),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 캘린더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _GlassContainer(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 15),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Colors.white70),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Colors.white70),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      weekdayStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.white70),
                      weekendTextStyle: const TextStyle(color: Colors.white60),
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: themeColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: themeColor.withOpacity(0.6), blurRadius: 12, spreadRadius: 1)
                        ],
                      ),
                      markerDecoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    eventLoader: _getEventsForDay,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 날짜 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Text(
                      _selectedDay != null
                          ? DateFormat('d MMM').format(_selectedDay!)
                          : 'Select Date',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    if (_selectedDay != null)
                      Text(
                        DateFormat('yyyy').format(_selectedDay!),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 28, fontWeight: FontWeight.w300),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 리스트
              Expanded(
                child: dailyEvents.isEmpty
                    ? Center(
                  child: Text(
                    "등록된 일정이 없습니다.",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: dailyEvents.length,
                  itemBuilder: (context, index) {
                    final event = dailyEvents[index];
                    final bool isOfficial = event['is_official'] ?? false;
                    final int id = event['id'];
                    final bool canDelete = isManager || !isOfficial;

                    final bool isFirst = index == 0;
                    final bool isLast = index == dailyEvents.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 40,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isFirst ? Colors.transparent : themeColor.withOpacity(0.3),
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                      color: isOfficial ? const Color(0xFFFFD700) : themeColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isOfficial ? const Color(0xFFFFD700) : themeColor).withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isLast ? Colors.transparent : themeColor.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () => _showDetailDialog(context, event, themeColor, isManager, canDelete),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isOfficial
                                            ? const Color(0xFFFFD700).withOpacity(0.3)
                                            : Colors.white.withOpacity(0.1),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event['title'] ?? 'No Title',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isOfficial)
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                                                ),
                                                child: const Text("공식", style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            if (canDelete)
                                              GestureDetector(
                                                onTap: () => _showDeleteConfirmDialog(context, id, isOfficial, isManager),
                                                child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white.withOpacity(0.4)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (event['start_time'] != null)
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatTimeRange(event['start_time'], event['end_time']),
                                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        if (event['description'] != null && event['description'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              event['description'],
                                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleFabClick(context, themeColor, isManager),
        backgroundColor: themeColor,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null) return '';
    final s = DateTime.parse(start).toLocal();
    final e = end != null ? DateTime.parse(end).toLocal() : s;
    return "${DateFormat('HH:mm').format(s)} - ${DateFormat('HH:mm').format(e)}";
  }

  // --------------------------------------------------------
  // 3. 팝업 & 다이얼로그
  // --------------------------------------------------------

  void _handleFabClick(BuildContext context, Color themeColor, bool isManager) {
    if (isManager) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: themeColor.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: themeColor),
                ),
                title: const Text('개인 일정 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('나만 볼 수 있는 일정입니다.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPersonalScheduleSheet(context, themeColor);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.school, color: Colors.orangeAccent),
                ),
                title: const Text('공식 세션(커리큘럼) 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('모든 부원에게 보이며, QR 출석 목록에 추가됩니다.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddOfficialCurriculumSheet(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } else {
      _showAddPersonalScheduleSheet(context, themeColor);
    }
  }

  // [개인 일정 추가 시트] - 기존과 동일, 생략 없이 포함
  void _showAddPersonalScheduleSheet(BuildContext context, Color themeColor) {
    DateTime now = DateTime.now();
    DateTime inputDate = _selectedDay ?? now;
    TimeOfDay startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: now.hour + 2, minute: 0);

    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
              return Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 24),
                          Text("새 일정 추가 (개인)", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 20),
                          _buildTextField(titleController, "제목", Icons.title, themeColor),
                          const SizedBox(height: 16),
                          _buildTextField(descController, "설명 (선택사항)", Icons.description_outlined, themeColor, maxLines: 2),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildTimePickerButton(context, "시작", startTime, themeColor, () async {
                                final time = await showTimePicker(context: context, initialTime: startTime);
                                if (time != null) setSheetState(() => startTime = time);
                              })),
                              const SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTimePickerButton(context, "종료", endTime, themeColor, () async {
                                final time = await showTimePicker(context: context, initialTime: endTime);
                                if (time != null) setSheetState(() => endTime = time);
                              })),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (titleController.text.isNotEmpty) {
                                  final startDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, startTime.hour, startTime.minute);
                                  final endDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, endTime.hour, endTime.minute);
                                  _addPersonalSchedule(title: titleController.text, description: descController.text, startTime: startDateTime, endTime: endDateTime);
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                              child: const Text("일정 생성", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // [수정] 공식 커리큘럼 추가 시트 (시간 선택 추가)
  void _showAddOfficialCurriculumSheet(BuildContext context) {
    final DateTime inputDate = _selectedDay ?? DateTime.now();
    final titleController = TextEditingController();
    final weekController = TextEditingController();
    final descController = TextEditingController();

    // 기본 시간 설정 (오후 6시 ~ 8시)
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);

    const Color officialColor = Colors.orangeAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
              return Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 24),
                          const Text("공식 세션 등록", style: TextStyle(color: officialColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          const Text("이 세션은 QR 출석 목록에 자동으로 추가됩니다.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 20),

                          _buildTextField(titleController, "세션 이름 (예: 1주차 세션)", Icons.school, officialColor),
                          const SizedBox(height: 16),
                          _buildTextField(weekController, "주차 (숫자만 입력)", Icons.calendar_today, officialColor),
                          const SizedBox(height: 16),
                          _buildTextField(descController, "설명 / 공지사항", Icons.description_outlined, officialColor, maxLines: 3),

                          const SizedBox(height: 20),
                          // [추가] 시간 선택 UI
                          Row(
                            children: [
                              Expanded(child: _buildTimePickerButton(context, "시작 시간", startTime, officialColor, () async {
                                final time = await showTimePicker(context: context, initialTime: startTime);
                                if (time != null) setSheetState(() => startTime = time);
                              })),
                              const SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTimePickerButton(context, "종료 시간", endTime, officialColor, () async {
                                final time = await showTimePicker(context: context, initialTime: endTime);
                                if (time != null) setSheetState(() => endTime = time);
                              })),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.event_available, color: Colors.white70, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                "날짜: ${DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(inputDate)}",
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (titleController.text.isNotEmpty && weekController.text.isNotEmpty) {
                                  final int week = int.tryParse(weekController.text) ?? 0;

                                  // 시간 데이터 병합
                                  final startDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, startTime.hour, startTime.minute);
                                  final endDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, endTime.hour, endTime.minute);

                                  _addOfficialCurriculum(
                                    title: titleController.text,
                                    description: descController.text,
                                    weekNumber: week,
                                    startTime: startDateTime, // 전달
                                    endTime: endDateTime,     // 전달
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: officialColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                              child: const Text("공식 세션 생성", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPopup(BuildContext context, String title, String message, Color themeColor, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? Colors.redAccent : Colors.greenAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("확인"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int id, bool isOfficial, bool isManager) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text("일정 삭제", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                isOfficial
                    ? "공식 세션입니다. 정말 삭제하시겠습니까?\n모든 부원의 캘린더에서 사라집니다."
                    : "정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("취소", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem(id, isOfficial, isManager);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("삭제"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> event, Color themeColor, bool isManager, bool canDelete) {
    final bool isOfficial = event['is_official'] ?? false;
    final int id = event['id'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOfficial ? const Color(0xFFFFD700).withOpacity(0.2) : themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOfficial ? const Color(0xFFFFD700) : themeColor,
                        ),
                      ),
                      child: Text(
                        isOfficial ? "OFFICIAL" : "PERSONAL",
                        style: TextStyle(
                          color: isOfficial ? const Color(0xFFFFD700) : themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  event['title'] ?? '제목 없음',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(DateTime.parse(event['start_time']).toLocal()),
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event['description'] != null && event['description'].toString().isNotEmpty
                        ? event['description']
                        : "설명이 없습니다.",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                if (canDelete)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmDialog(context, id, isOfficial, isManager);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text("일정 삭제", style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, Color color, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      cursorColor: color,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color)),
      ),
    );
  }

  Widget _buildTimePickerButton(BuildContext context, String label, TimeOfDay time, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(children: [Icon(Icons.access_time, color: color, size: 18), const SizedBox(width: 8), Text(time.format(context), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: child,
        ),
      ),
    );
  }
}