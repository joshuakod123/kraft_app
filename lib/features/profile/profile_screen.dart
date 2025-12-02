import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../auth/auth_provider.dart'; // [필수] userDataProvider 사용

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int attendedCount = 0;
  int totalSessions = 16;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final stats = await SupabaseRepository().getAttendanceStats();
    if (mounted) {
      setState(() {
        attendedCount = stats['attended'] ?? 0;
        totalSessions = stats['total'] ?? 16;
      });
    }
  }

  void _showEdit(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name']);
    final schoolCtrl = TextEditingController(text: user['school']);
    final majorCtrl = TextEditingController(text: user['major']);
    final studentIdCtrl = TextEditingController(text: user['student_id']);
    final ageCtrl = TextEditingController(text: user['age']?.toString());
    final phoneCtrl = TextEditingController(text: user['phone']);
    String? selectedGender = user['gender'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, "Name"),
              _field(schoolCtrl, "School"),
              _field(majorCtrl, "Major"),
              // [기능] 학번 입력 시 '학번' Suffix 표시
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: TextField(
                  controller: studentIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Student ID",
                      suffixText: "학번",
                      suffixStyle: TextStyle(color: Colors.white54),
                      filled: true, fillColor: Colors.black54
                  ),
                ),
              ),
              _field(ageCtrl, "Age", isNumber: true),
              _field(phoneCtrl, "Phone"),
              DropdownButtonFormField<String>(
                value: ['Male', 'Female', 'Other'].contains(selectedGender) ? selectedGender : null,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Gender', filled: true, fillColor: Colors.black54),
                items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => selectedGender = v,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await SupabaseRepository().updateUserProfile(
                name: nameCtrl.text,
                major: majorCtrl.text,
                phone: phoneCtrl.text,
                teamId: user['team_id'] ?? 1,
                school: schoolCtrl.text,
                studentId: studentIdCtrl.text,
                age: int.tryParse(ageCtrl.text),
                gender: selectedGender,
              );
              ref.invalidate(userDataProvider);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String l, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: l, filled: true, fillColor: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text("No Profile"));
          final double rate = (totalSessions > 0) ? (attendedCount / totalSessions).clamp(0.0, 1.0) : 0.0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [dept.color.withOpacity(0.3), Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/images/logo.png')),
                        const SizedBox(height: 10),
                        Text(user['name'] ?? 'User', style: GoogleFonts.chakraPetch(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("${dept.name.toUpperCase()} TEAM", style: TextStyle(color: dept.color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showEdit(user)),
                  IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () => ref.read(authProvider.notifier).signOut())
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GlassContainer.clearGlass(
                        height: 120, width: double.infinity, borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(value: rate, color: dept.color, strokeWidth: 8),
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Attendance", style: TextStyle(color: Colors.grey)),
                                Text("$attendedCount / $totalSessions", style: TextStyle(color: dept.color, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // [요청 반영] 개인정보 숨김 및 학번 뒤 '학번' 표시
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          _row("School", user['school']),
                          _divider(),
                          _row("Major", user['major']),
                          _divider(),
                          // 학번 뒤에 글자 붙이기
                          _row("Student ID", user['student_id'] != null ? "${user['student_id']}학번" : null),
                          _divider(),
                          _row("Age", user['age']?.toString()),
                          _divider(),
                          _row("Gender", user['gender']),
                        ]),
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _row(String k, String? v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text(k, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(v ?? '-', style: const TextStyle(color: Colors.white))]));
  Widget _divider() => Divider(color: Colors.white.withOpacity(0.1));
}