import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        // Repository가 '*'를 select 한다면 cohort도 자동으로 가져옵니다.
        future: SupabaseRepository().getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          // --- [데이터 가져오기 및 한글화 준비] ---
          final name = user?['name'] ?? 'Member';
          final major = user?['major'] ?? '미입력';
          final school = user?['school'] ?? '미입력';
          final studentId = user?['student_id'] ?? '미입력';
          final gender = user?['gender'] ?? '-';

          // 기수 데이터 가져오기 (DB 컬럼: cohort)
          final cohort = user?['cohort'];
          final cohortString = cohort != null ? '${cohort}기' : '-';

          final role = user?['role'] ?? 'member';
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
                        backgroundColor: dept.color.withOpacity(0.2), // withValues 대신 호환성 위해 withOpacity 사용
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
                              role == 'manager' ? '임원진' : '멤버', // 한글화
                              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  // [2] 정보 타일들 (한글 라벨 적용)
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile("대학", school)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoTile("학번", studentId)),
                    ],
                  ),

                  // [수정됨] 전공 옆에 기수 배치
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile("전공", major)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoTile("기수", cohortString, color: AppTheme.primaryColor)), // 기수는 강조 색상
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(child: _buildInfoTile("성별", gender)),
                      const SizedBox(width: 16),
                      // Department -> 부서 (enum name 대신 한글명 사용 추천, 일단 dept.name 유지)
                      Expanded(child: _buildInfoTile("부서", dept.name, color: dept.color)),
                    ],
                  ),

                  _buildInfoTile("이메일", SupabaseRepository().currentUser?.email ?? ''),

                  const Spacer(),

                  // [3] MY ARCHIVE 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/archive'),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text("내 아카이브", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dept.color,
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
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: const Text("로그아웃", style: TextStyle(fontWeight: FontWeight.bold)),
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

// AppTheme.primaryColor가 없다면 Colors.blue 등으로 대체하세요.
class AppTheme {
  static const primaryColor = Color(0xFF6C63FF);
}