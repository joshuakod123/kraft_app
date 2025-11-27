import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../features/auth/auth_provider.dart';

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
          final name = user?['name'] ?? 'Member';
          final major = user?['major'] ?? 'Unknown';
          final studentId = user?['student_id'] ?? '---';
          final teamId = user?['team_id'] ?? 1;

          // Enum에서 팀 정보 찾기 (기본값 Business)
          final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
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
                          Text(dept.name, style: TextStyle(color: dept.color, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  _buildInfoTile("Student ID", studentId),
                  _buildInfoTile("Major", major),
                  _buildInfoTile("Email", SupabaseRepository().currentUser?.email ?? ''),
                  _buildInfoTile("Phone", user?['phone'] ?? ''),

                  const Spacer(),

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
                  const SizedBox(height: 80), // 하단 바 공간 확보
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}