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

  List<CalendarEvent> _getEventsForDay(DateTime day, List<CalendarEvent> allEvents) {
    return allEvents.where((event) => isSameDay(event.date, day)).toList();
  }

  // [기능] 상세 보기 팝업 (삭제 기능 포함)
  void _showDetailDialog(CalendarEvent event, bool isManager) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer.clearGlass(
          height: 400,
          width: double.infinity,
          borderRadius: BorderRadius.circular(20),
          borderWidth: 1.0,
          // 테두리 색상: 공식이면 Cyan, 개인이면 Purple (구분을 위해 유지하되, 부서색 고려 가능)
          borderColor: event.isOfficial ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.purpleAccent.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.isOfficial ? "OFFICIAL" : "PERSONAL",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      // [삭제 버튼] 개인 일정이거나, 매니저인 경우 표시
                      if (!event.isOfficial || isManager)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text("Delete Schedule", style: TextStyle(color: Colors.white)),
                                content: const Text("Are you sure?", style: TextStyle(color: Colors.grey)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              if (event.isOfficial) {
                                await SupabaseRepository().deleteCurriculum(event.id);
                              } else {
                                await SupabaseRepository().deletePersonalSchedule(event.id);
                              }
                              // 목록 갱신
                              ref.invalidate(calendarEventsProvider);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              Text(event.title, style: GoogleFonts.chakraPetch(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time_filled, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "${DateFormat('HH:mm').format(event.date)} ~ ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : '??:??'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    event.description.isNotEmpty ? event.description : "No description provided.",
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [일정 추가 팝업]
  void _showAddEventDialog(bool isManager, Department dept) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isOfficial = false;

    DateTime date = _selectedDay ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime(bool isStart) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: isStart ? startTime : endTime,
            );
            if (picked != null) {
              setDialogState(() {
                if (isStart) startTime = picked;
                else endTime = picked;
              });
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Add Schedule", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isManager) ...[
                    Row(children: [
                      Expanded(child: ChoiceChip(label: const Center(child: Text("Personal")), selected: !isOfficial, onSelected: (v) => setDialogState(() => isOfficial = !v), selectedColor: Colors.purpleAccent, backgroundColor: Colors.black54, labelStyle: TextStyle(color: !isOfficial ? Colors.black : Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(child: ChoiceChip(label: const Center(child: Text("Official")), selected: isOfficial, onSelected: (v) => setDialogState(() => isOfficial = v), selectedColor: Colors.cyanAccent, backgroundColor: Colors.black54, labelStyle: TextStyle(color: isOfficial ? Colors.black : Colors.white))),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildFancyTextField(titleCtrl, 'Title', dept.color),
                  const SizedBox(height: 12),
                  _buildFancyTextField(descCtrl, 'Description', dept.color, maxLines: 3),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setDialogState(() => date = picked);
                          },
                          child: Row(children: [const Icon(Icons.calendar_today, color: Colors.grey, size: 16), const SizedBox(width: 8), Text(DateFormat('yyyy.MM.dd (E)').format(date), style: const TextStyle(color: Colors.white))]),
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => pickTime(true),
                              child: Row(children: [const Icon(Icons.access_time, color: Colors.greenAccent, size: 16), const SizedBox(width: 8), Text(startTime.format(context), style: const TextStyle(color: Colors.white))]),
                            ),
                            const Text("~", style: TextStyle(color: Colors.grey)),
                            InkWell(
                              onTap: () => pickTime(false),
                              child: Row(children: [Text(endTime.format(context), style: const TextStyle(color: Colors.white)), const SizedBox(width: 8), const Icon(Icons.access_time, color: Colors.redAccent, size: 16)]),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    final startDateTime = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                    final endDateTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

                    if (isOfficial) {
                      await SupabaseRepository().addCurriculum(titleCtrl.text, descCtrl.text, startDateTime, endDateTime, dept.id);
                    } else {
                      await SupabaseRepository().addPersonalSchedule(titleCtrl.text, descCtrl.text, startDateTime, endDateTime);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(calendarEventsProvider);
                    }
                  }
                },
                // [수정] 다이얼로그 추가 버튼도 부서 색상으로
                style: ElevatedButton.styleFrom(backgroundColor: dept.color, foregroundColor: Colors.black),
                child: const Text("Add"),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFancyTextField(TextEditingController ctrl, String hint, Color deptColor, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black54,
        // [수정] 포커스 시 부서 색상 테두리
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: deptColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          // [수정] FAB 색상을 부서 고유 색상으로 변경
          backgroundColor: dept.color,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.black),
          onPressed: () => _showAddEventDialog(isManager, dept),
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
                currentDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) => setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }),
                eventLoader: (day) => _getEventsForDay(day, allEvents),
                headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white), rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white)),
                calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white54),
                    outsideTextStyle: const TextStyle(color: Colors.white24),
                    todayDecoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    // [수정] 선택된 날짜 마커를 부서 색상으로
                    selectedDecoration: BoxDecoration(color: dept.color, shape: BoxShape.circle)
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((e) {
                        final event = e as CalendarEvent;
                        // 마커는 공식(Cyan) / 개인(Purple) 구분 유지 (이게 더 직관적일 수 있음)
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.0),
                          width: 6, height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent),
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = selectedEvents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: GestureDetector(
                    onTap: () => _showDetailDialog(event, isManager), // 상세 팝업
                    child: GlassContainer.clearGlass(
                      height: 80, width: double.infinity, borderRadius: BorderRadius.circular(16),
                      borderWidth: 1.0, borderColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(width: 4, height: 40, decoration: BoxDecoration(color: event.isOfficial ? Colors.cyanAccent : Colors.purpleAccent, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  "${DateFormat('HH:mm').format(event.date)} ~ ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : ''} | ${event.description}",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}