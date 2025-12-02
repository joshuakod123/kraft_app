import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';
import '../auth/auth_provider.dart'; // [필수] userDataProvider, authProvider

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // 출석 데이터 상태
  int attendedCount = 0;
  int totalSessions = 16; // 기본 총 세션 수

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  // 출석 데이터 로딩
  Future<void> _loadAttendance() async {
    final stats = await SupabaseRepository().getAttendanceStats();
    if (mounted) {
      setState(() {
        attendedCount = stats['attended'] ?? 0;
        totalSessions = stats['total'] ?? 16;
      });
    }
  }

  // 프로필 수정 다이얼로그 표시
  void _showEditProfileDialog(Map<String, dynamic> user) {
    // 기존 데이터로 컨트롤러 초기화 (Null 체크 포함)
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final schoolCtrl = TextEditingController(text: user['school'] ?? '');
    final majorCtrl = TextEditingController(text: user['major'] ?? '');
    final idCtrl = TextEditingController(text: user['student_id'] ?? '');
    final ageCtrl = TextEditingController(text: user['age']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');

    // 성별 드롭다운 초기값 설정 (목록에 없는 값이면 null 처리)
    String? selectedGender = user['gender'];
    const genderOptions = ['Male', 'Female', 'Other'];
    if (selectedGender != null && !genderOptions.contains(selectedGender)) {
      selectedGender = null;
    }

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
              // 성별 선택 드롭다운
              DropdownButtonFormField<String>(
                value: selectedGender,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black54,
                  border: OutlineInputBorder(),
                ),
                items: genderOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => selectedGender = v,
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
              // 업데이트 요청
              await SupabaseRepository().updateUserProfile(
                name: nameCtrl.text,
                major: majorCtrl.text,
                phone: phoneCtrl.text,
                teamId: user['team_id'] ?? 1, // 기존 팀 ID 유지
                school: schoolCtrl.text,
                studentId: idCtrl.text,
                age: int.tryParse(ageCtrl.text),
                gender: selectedGender,
              );

              // 프로필 UI 갱신을 위해 Provider 초기화
              ref.invalidate(userDataProvider);

              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // 수정 입력 필드 위젯
  Widget _buildEditField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.black54,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
        error: (err, stack) => Center(child: Text("Error loading profile: $err", style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null) return const Center(child: Text("No user data found", style: TextStyle(color: Colors.white)));

          // 출석률 계산 (0으로 나누기 방지)
          final double attendanceRate = (totalSessions > 0)
              ? (attendedCount / totalSessions).clamp(0.0, 1.0)
              : 0.0;

          return CustomScrollView(
            slivers: [
              // 1. 상단 앱바 (프로필 사진, 이름, 부서)
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [dept.color.withOpacity(0.3), Colors.black],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20), // 상단 여백
                          Container(
                            padding: const EdgeInsets.all(4), // 테두리 두께
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: dept.color, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.black,
                              backgroundImage: AssetImage('assets/images/logo.png'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user['name'] ?? 'User',
                            style: GoogleFonts.chakraPetch(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            "${dept.name.toUpperCase()} TEAM",
                            style: TextStyle(color: dept.color, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditProfileDialog(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                  )
                ],
              ),

              // 2. 메인 컨텐츠 (출석, 정보)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 출석 현황판 ---
                      Text("ATTENDANCE TRACKER", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      GlassContainer.clearGlass(
                        height: 140,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(20),
                        borderColor: Colors.white.withOpacity(0.1),
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // 원형 차트
                            SizedBox(
                              width: 90, height: 90,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: attendanceRate,
                                    strokeWidth: 10,
                                    color: dept.color,
                                    backgroundColor: Colors.white10,
                                  ),
                                  Center(
                                    child: Text(
                                      "${(attendanceRate * 100).toInt()}%",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // 텍스트 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Total Sessions: $totalSessions", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Text("Attended: $attendedCount", style: TextStyle(color: dept.color, fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text("Missed: ${totalSessions - attendedCount}", style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // --- 개인 정보 카드 ---
                      Text("PERSONAL INFO", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
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
                      const SizedBox(height: 100), // 하단 여백
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

  // 정보 행 위젯
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  // 구분선 위젯
  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.08), height: 24);
}