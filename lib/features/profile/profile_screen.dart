import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../auth/auth_provider.dart';

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

  void _showEditProfileDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name']);
    final schoolCtrl = TextEditingController(text: user['school'] ?? '');
    final majorCtrl = TextEditingController(text: user['major'] ?? '');
    final idCtrl = TextEditingController(text: user['student_id'] ?? '');
    final ageCtrl = TextEditingController(text: user['age']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    String? selectedGender = user['gender'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Edit Profile", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField(nameCtrl, "Name"),
              _buildEditField(schoolCtrl, "School"),
              _buildEditField(majorCtrl, "Major"),
              _buildEditField(idCtrl, "Student ID"),
              _buildEditField(ageCtrl, "Age", isNumber: true),
              _buildEditField(phoneCtrl, "Phone"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGender,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.black54),
                items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => selectedGender = v,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await SupabaseRepository().updateUserProfile(
                name: nameCtrl.text,
                major: majorCtrl.text,
                phone: phoneCtrl.text,
                teamId: user['team_id'] ?? 1,
                school: schoolCtrl.text,
                studentId: idCtrl.text,
                age: int.tryParse(ageCtrl.text),
                gender: selectedGender,
              );
              ref.invalidate(userDataProvider);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: Colors.black54),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null) return const Center(child: Text("No user data", style: TextStyle(color: Colors.white)));

          final double attendanceRate = (totalSessions > 0) ? (attendedCount / totalSessions).clamp(0.0, 1.0) : 0.0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [dept.color.withOpacity(0.3), Colors.black]),
                    ),
                    child: Center(
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
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showEditProfileDialog(user)),
                  IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () => ref.read(authProvider.notifier).signOut())
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ATTENDANCE TRACKER", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      GlassContainer.clearGlass(
                        height: 120, width: double.infinity, borderRadius: BorderRadius.circular(16), borderColor: Colors.white10, padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80, height: 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(value: attendanceRate, strokeWidth: 8, color: dept.color, backgroundColor: Colors.white10),
                                  Center(child: Text("${(attendanceRate * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Total Sessions: $totalSessions", style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text("Attended: $attendedCount", style: TextStyle(color: dept.color, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Missed: ${totalSessions - attendedCount}", style: const TextStyle(color: Colors.redAccent)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text("PERSONAL INFO", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.school, "School", user['school'] ?? '-'),
                            _buildDivider(),
                            _buildInfoRow(Icons.book, "Major", user['major'] ?? '-'),
                            _buildDivider(),
                            _buildInfoRow(Icons.badge, "Student ID", user['student_id'] ?? '-'),
                            _buildDivider(),
                            _buildInfoRow(Icons.cake, "Age", user['age'] != null ? "${user['age']}" : '-'),
                            _buildDivider(),
                            _buildInfoRow(Icons.person, "Gender", user['gender'] ?? '-'),
                            _buildDivider(),
                            _buildInfoRow(Icons.phone, "Phone", user['phone'] ?? '-'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.05));
}