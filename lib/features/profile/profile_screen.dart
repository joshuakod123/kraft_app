import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../features/auth/auth_provider.dart';
import '../../core/state/global_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: SupabaseRepository().getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          // DB 필드 가져오기
          final name = user?['name'] ?? 'Member';
          final major = user?['major'] ?? 'Unknown';

          // [추가] 새로 추가된 필드들
          final school = user?['school'] ?? 'Univ';
          final studentId = user?['student_id'] ?? 'ID';
          final gender = user?['gender'] ?? '-';
          final role = user?['role'] ?? 'member'; // 'manager' or 'member'

          final teamId = user?['team_id'] ?? 1;
          final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // [1] 상단 프로필 헤더
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: dept.color.withValues(alpha: 0.2),
                        child: Icon(dept.icon, size: 40, color: dept.color),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.chakraPetch(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: role == 'manager' ? Colors.yellowAccent : dept.color,
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                              role.toString().toUpperCase(), // MEMBER or MANAGER
                              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  // [2] 정보 타일들 (전화번호 제거됨, 학교/학번/성별 추가됨)
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile("University", school)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoTile("Student ID", studentId)),
                    ],
                  ),
                  _buildInfoTile("Major", major),

                  Row(
                    children: [
                      Expanded(child: _buildInfoTile("Gender", gender)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoTile("Department", dept.name, color: dept.color)),
                    ],
                  ),

                  _buildInfoTile("Email", SupabaseRepository().currentUser?.email ?? ''),

                  const Spacer(),

                  // [3] MY ARCHIVE 버튼 (추가됨)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/archive'), // 아카이브 화면으로 이동
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text("MY ARCHIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dept.color, // 부서 색상 적용
                        side: BorderSide(color: dept.color, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // [4] 로그아웃 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}