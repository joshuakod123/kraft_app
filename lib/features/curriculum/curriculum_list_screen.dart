import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';
import 'curriculum_provider.dart';

class CurriculumListScreen extends ConsumerStatefulWidget {
  const CurriculumListScreen({super.key});

  @override
  ConsumerState<CurriculumListScreen> createState() => _CurriculumListScreenState();
}

class _CurriculumListScreenState extends ConsumerState<CurriculumListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  // 날짜별 이벤트 필터링
  List<CalendarEvent> _getEventsForDay(DateTime day, List<CalendarEvent> allEvents) {
    return allEvents.where((event) => isSameDay(event.date, day)).toList();
  }

  void _showAddEventDialog(bool isManager, int teamId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isOfficial = false;
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Add Schedule", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isManager)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Personal")),
                              selected: !isOfficial,
                              onSelected: (v) => setDialogState(() => isOfficial = !v),
                              selectedColor: Colors.purpleAccent.withValues(alpha: 0.8),
                              backgroundColor: Colors.black54,
                              labelStyle: TextStyle(color: !isOfficial ? Colors.black : Colors.white60, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Official")),
                              selected: isOfficial,
                              onSelected: (v) => setDialogState(() => isOfficial = v),
                              selectedColor: Colors.cyanAccent.withValues(alpha: 0.8),
                              backgroundColor: Colors.black54,
                              labelStyle: TextStyle(color: isOfficial ? Colors.black : Colors.white60, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildFancyTextField(titleCtrl, 'Title'),
                  const SizedBox(height: 12),
                  _buildFancyTextField(descCtrl, 'Description', maxLines: 3),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                        const SizedBox(width: 10),
                        Text(DateFormat('yyyy.MM.dd (E)').format(selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: isOfficial ? Colors.cyanAccent : Colors.purpleAccent,
                                      onPrimary: Colors.black,
                                      surface: const Color(0xFF1E1E1E),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setDialogState(() => selectedDate = picked);
                          },
                          child: Text("Change", style: TextStyle(color: isOfficial ? Colors.cyanAccent : Colors.purpleAccent)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    if (isOfficial) {
                      await SupabaseRepository().addCurriculum(titleCtrl.text, descCtrl.text, selectedDate, teamId);
                    } else {
                      await SupabaseRepository().addPersonalSchedule(titleCtrl.text, descCtrl.text, selectedDate);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      // 리스트 갱신 (선택적)
                      ref.invalidate(calendarEventsProvider);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOfficial ? Colors.cyanAccent : Colors.purpleAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFancyTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black54,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(calendarEventsProvider);
    final dept = ref.watch(currentDeptProvider);
    final isManager = ref.watch(isManagerProvider);
    final selectedEvents = _getEventsForDay(_selectedDay ?? DateTime.now(), allEvents);

    return Scaffold(
      backgroundColor: Colors.black,
      // [수정] Floating Action Button 위치 조정
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // 네비게이션 바 위로 올림
        child: FloatingActionButton(
          backgroundColor: isManager ? Colors.cyanAccent : Colors.purpleAccent,
          shape: const CircleBorder(), // 완전한 원형
          elevation: 10,
          child: const Icon(Icons.add, color: Colors.black, size: 28),
          onPressed: () => _showAddEventDialog(isManager, dept.id),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 10),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getEventsForDay(day, allEvents),

                // 스타일링
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white54),
                  outsideTextStyle: const TextStyle(color: Colors.white24),
                  selectedDecoration: BoxDecoration(
                    color: dept.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: dept.color.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                  todayDecoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle), // 기본 마커
                ),
                // 커스텀 마커
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((e) { // 최대 3개까지만 표시
                        final event = e as CalendarEvent;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.0),
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Text(
                DateFormat('MMMM d, EEEE').format(_selectedDay ?? DateTime.now()),
                style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (selectedEvents.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: Text("No events", style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final event = selectedEvents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Dismissible(
                      key: ValueKey(event.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (dir) async {
                        if (!isManager && event.isOfficial) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("공식 일정은 삭제할 수 없습니다.")));
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (dir) async {
                        if (event.isOfficial) {
                          await SupabaseRepository().deleteCurriculum(event.id);
                        } else {
                          await SupabaseRepository().deletePersonalSchedule(event.id);
                        }
                        ref.invalidate(calendarEventsProvider);
                      },
                      child: GlassContainer.clearGlass(
                        height: 80, width: double.infinity, borderRadius: BorderRadius.circular(16),
                        borderWidth: 1.0,
                        borderColor: event.isOfficial
                            ? Colors.cyanAccent.withValues(alpha: 0.3)
                            : Colors.purpleAccent.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 4, height: 40,
                              decoration: BoxDecoration(
                                  color: event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: (event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent).withValues(alpha: 0.5),
                                        blurRadius: 8
                                    )
                                  ]
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(event.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12), maxLines: 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: selectedEvents.length,
              ),
            ),
          // [수정] 리스트 마지막 여백 추가 (FAB에 가려지지 않게)
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}