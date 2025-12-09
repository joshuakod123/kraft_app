import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import 'dart:ui';

import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../core/state/global_providers.dart';

// Provider 등 상단 코드는 그대로 유지
final teamMembersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dept = ref.watch(currentDeptProvider);
  return SupabaseRepository().getTeamMembers(dept.id);
});

class TeamMemberScreen extends ConsumerWidget {
  const TeamMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = ref.watch(currentDeptProvider);
    final membersAsync = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        title: Text(
          '${dept.name} TEAM',
          style: GoogleFonts.chakraPetch(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              const Color(0xFF121212),
              dept.color.withOpacity(0.15),
            ],
          ),
        ),
        child: membersAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: dept.color)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          data: (members) {
            return Column(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Text(
                        "MEMBERS LIST",
                        style: GoogleFonts.chakraPetch(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dept.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: dept.color.withOpacity(0.5)),
                        ),
                        child: Text(
                          "${members.length} Active",
                          style: TextStyle(color: dept.color, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: members.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == members.length) return const SizedBox(height: 120);
                      final member = members[index];
                      return _buildMemberTile(context, member, dept);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> user, Department dept) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'member';
    // 기수 정보 리스트에도 표시 (선택사항)
    final cohort = user['cohort'];

    final isManager = role == 'manager';
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProfileDialog(context, user, dept),
        borderRadius: BorderRadius.circular(16),
        splashColor: dept.color.withOpacity(0.3),
        highlightColor: dept.color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isManager ? dept.color.withOpacity(0.6) : Colors.white.withOpacity(0.08),
              width: isManager ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'avatar-${user['id']}',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isManager ? dept.color : const Color(0xFF333333),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isManager)
                        BoxShadow(color: dept.color.withOpacity(0.4), blurRadius: 10),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: isManager ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // 리스트에서 이름 옆에 작게 기수 표시
                        if (cohort != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            "${cohort}기",
                            style: TextStyle(color: dept.color.withOpacity(0.8), fontSize: 12),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isManager)
                Icon(Icons.stars_rounded, color: dept.color, size: 24)
              else
                Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, Map<String, dynamic> user, Department dept) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Profile",
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return MemberProfileCard(user: user, dept: dept);
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 상세 프로필 팝업 카드 (한글화 및 기수 연동)
// -----------------------------------------------------------------------------
class MemberProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Department dept;

  const MemberProfileCard({
    super.key,
    required this.user,
    required this.dept,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? '알 수 없음';
    final email = user['email'] ?? '-';
    final major = user['major'] ?? '전공 미입력';
    final studentId = user['student_id'] ?? '미입력';
    final role = user['role'] ?? 'member';
    final school = user['school'] ?? '대학교';
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';

    // [수정] DB에서 기수 정보 가져오기
    final cohort = user['cohort'];
    final generationString = cohort != null ? "${cohort}기" : "기수 미정";

    final isManager = role == 'manager';
    final themeColor = isManager ? dept.color : Colors.white;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: GlassContainer(
            width: MediaQuery.of(context).size.width * 0.85,
            borderRadius: BorderRadius.circular(24),
            borderWidth: 1.5,
            borderColor: themeColor.withOpacity(0.3),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E1E1E).withOpacity(0.9),
                const Color(0xFF121212).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            blur: 20.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [1. 상단 배너 및 아바타]
                SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [dept.color.withOpacity(0.8), dept.color.withOpacity(0.3)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        child: Hero(
                          tag: 'avatar-${user['id']}',
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              border: Border.all(color: themeColor, width: 4),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // [2. 이름 및 학교/전공]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          "$school · $major",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // [3. 정보 박스 (한글 라벨)]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 첫 번째 줄: 학번 & 기수
                      Row(
                        children: [
                          Expanded(child: _buildInfoBox("학번", studentId, Icons.badge_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoBox("기수", generationString, Icons.school_outlined)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 두 번째 줄: 역할
                      _buildRoleBox(isManager, dept),

                      const SizedBox(height: 12),

                      // 세 번째 줄: 이메일
                      _buildInfoBox("이메일", email, Icons.alternate_email_rounded, isFullWidth: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // [4. 닫기 버튼]
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("닫기", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBox(bool isManager, Department dept) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isManager ? dept.color.withOpacity(0.15) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isManager ? dept.color.withOpacity(0.5) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isManager ? Icons.verified_user_rounded : Icons.person_rounded,
            color: isManager ? dept.color : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isManager ? "운영진 / 매니저" : "일반 멤버",
            style: TextStyle(
              color: isManager ? dept.color : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}