import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// [Provider 및 Enum 연결]
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';

class CurriculumListScreen extends ConsumerStatefulWidget {
  const CurriculumListScreen({super.key});

  @override
  ConsumerState<CurriculumListScreen> createState() => _CurriculumListScreenState();
}

class _CurriculumListScreenState extends ConsumerState<CurriculumListScreen> {
  final _supabase = Supabase.instance.client;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSchedules();
    });
  }

  // --------------------------------------------------------
  // 1. 데이터 로직
  // --------------------------------------------------------
  Future<void> _fetchSchedules() async {
    try {
      final myDept = ref.read(currentDeptProvider);
      final myUserId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('schedules')
          .select()
          .order('start_time', ascending: true);

      final data = response as List<dynamic>;
      Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

      for (var item in data) {
        final String? itemDept = item['department'];
        final String? itemUserId = item['user_id'];
        final bool isOfficial = item['is_official'] ?? false;

        bool show = false;
        if (itemUserId == myUserId) {
          show = true;
        } else if (isOfficial && itemDept == myDept.name) {
          show = true;
        }

        if (!show) continue;

        DateTime startDate = DateTime.parse(item['start_time']).toLocal();
        DateTime dateKey = DateTime(startDate.year, startDate.month, startDate.day);

        if (newEvents[dateKey] == null) {
          newEvents[dateKey] = [];
        }
        newEvents[dateKey]!.add(item);
      }

      if (mounted) {
        setState(() {
          _events = newEvents;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _addSchedule({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required bool isOfficial,
  }) async {
    final myDept = ref.read(currentDeptProvider);

    try {
      await _supabase.from('schedules').insert({
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_official': isOfficial,
        'department': myDept.name,
        'user_id': _supabase.auth.currentUser?.id,
      });

      await _fetchSchedules();

      if (mounted) {
        // [수정] 스낵바 대신 팝업 호출
        _showPopup(context, "성공", "일정이 추가되었습니다!", myDept.color);
      }
    } catch (e) {
      debugPrint('Error adding schedule: $e');
      if (mounted) {
        _showPopup(context, "오류", "일정 추가에 실패했습니다.\n$e", Colors.redAccent, isError: true);
      }
    }
  }

  Future<void> _deleteSchedule(int id, bool isOfficial, bool isManager) async {
    if (isOfficial && !isManager) {
      _showPopup(context, "권한 없음", "공식 일정은 임원만 삭제할 수 있습니다.", Colors.redAccent, isError: true);
      return;
    }

    try {
      await _supabase.from('schedules').delete().eq('id', id);
      await _fetchSchedules();
      if (mounted) {
        _showPopup(context, "삭제 완료", "일정이 삭제되었습니다.", Colors.greenAccent);
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
      if (mounted) {
        _showPopup(context, "오류", "삭제에 실패했습니다.", Colors.redAccent, isError: true);
      }
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
            onPressed: _fetchSchedules,
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
                                                child: const Text("공식 일정", style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            if (canDelete)
                                              GestureDetector(
                                                onTap: () => _showDeleteConfirmDialog(context, id, isOfficial, isManager),
                                                child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white.withOpacity(0.4)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
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
        onPressed: () => _showAddScheduleSheet(context, themeColor, isManager),
        backgroundColor: themeColor,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null || end == null) return '';
    final s = DateTime.parse(start).toLocal();
    final e = DateTime.parse(end).toLocal();
    return "${DateFormat('HH:mm').format(s)} - ${DateFormat('HH:mm').format(e)}";
  }

  // --------------------------------------------------------
  // 3. 팝업 & 다이얼로그 (한국어 적용)
  // --------------------------------------------------------

  // [NEW] 중앙 팝업 알림 (스낵바 대체)
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

  // 상세 보기 팝업
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
                        isOfficial ? "공식 일정" : "개인 일정",
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
                    const Icon(Icons.access_time, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "${DateFormat('yyyy.MM.dd (E)').format(DateTime.parse(event['start_time']).toLocal())}   " +
                          _formatTimeRange(event['start_time'], event['end_time']),
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

  void _showAddScheduleSheet(BuildContext context, Color themeColor, bool isManager) {
    DateTime now = DateTime.now();
    DateTime inputDate = _selectedDay ?? now;
    TimeOfDay startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: now.hour + 2, minute: 0);

    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isOfficial = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
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
                        Text("새 일정 추가", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                        const SizedBox(height: 24),
                        if (isManager)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Text("공식 일정", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Switch(
                                  value: isOfficial,
                                  activeColor: const Color(0xFF1E1E1E),
                                  activeTrackColor: themeColor,
                                  onChanged: (val) => setSheetState(() => isOfficial = val),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleController.text.isNotEmpty) {
                                final startDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, startTime.hour, startTime.minute);
                                final endDateTime = DateTime(inputDate.year, inputDate.month, inputDate.day, endTime.hour, endTime.minute);
                                _addSchedule(title: titleController.text, description: descController.text, startTime: startDateTime, endTime: endDateTime, isOfficial: isOfficial);
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
        );
      },
    );
  }

  // [수정] 삭제 확인 팝업 (한국어)
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
                "정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
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
                        _deleteSchedule(id, isOfficial, isManager);
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