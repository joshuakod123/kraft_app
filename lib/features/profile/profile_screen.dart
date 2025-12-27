import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import '../../features/auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // [New] 화면 진입 시 임시 비밀번호 여부 체크
  @override
  void initState() {
    super.initState();
    _checkTempPasswordStatus();
  }

  Future<void> _checkTempPasswordStatus() async {
    // 화면 빌드가 끝난 후 실행
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final profile = await SupabaseRepository().getUserProfile();

      // 임시 비밀번호 사용자라면 강제 변경 팝업 띄우기
      if (profile != null && profile['is_temp_password'] == true) {
        if (!mounted) return;

        // 사용자의 팀 색상 가져오기 (없으면 기본값)
        final teamId = profile['team_id'] ?? 1;
        final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

        showDialog(
          context: context,
          barrierDismissible: false, // 배경 클릭해서 닫기 방지 (강제 변경)
          builder: (context) => _ChangePasswordDialog(
            isForced: true,
            pointColor: dept.color, // 팀 색상 전달
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          final major = user?['major'] ?? '미입력';
          final school = user?['school'] ?? '미입력';
          final studentId = user?['student_id'] ?? '미입력';
          final gender = user?['gender'] ?? '-';
          final cohort = user?['cohort'];
          final cohortString = cohort != null ? '${cohort}기' : '-';
          final role = user?['role'] ?? 'member';
          final teamId = user?['team_id'] ?? 1;

          // [중요] 여기서 결정된 dept.color를 버튼 등에 사용
          final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // [1] 상단 프로필 헤더
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: dept.color.withOpacity(0.2),
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
                                        role == 'manager' ? '임원진' : '멤버',
                                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 40),

                            // [2] 정보 타일들
                            Row(
                              children: [
                                Expanded(child: _buildInfoTile("대학", school)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildInfoTile("학번", studentId)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: _buildInfoTile("전공", major)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildInfoTile("기수", cohortString, color: AppTheme.primaryColor)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: _buildInfoTile("성별", gender)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildInfoTile("부서", dept.name, color: dept.color)),
                              ],
                            ),

                            _buildInfoTile("이메일", SupabaseRepository().currentUser?.email ?? ''),

                            const Spacer(),
                            const SizedBox(height: 24),

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

                            // [4] 비밀번호 변경 버튼 (팀 컬러 적용)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _ChangePasswordDialog(pointColor: dept.color),
                                  );
                                },
                                icon: const Icon(Icons.lock_reset_rounded),
                                label: const Text("비밀번호 변경", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // [5] 로그아웃 버튼
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
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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

// [수정됨] 비밀번호 변경 팝업 위젯 (팀 컬러 지원)
class _ChangePasswordDialog extends StatefulWidget {
  final bool isForced;
  final Color pointColor; // 팀 색상

  const _ChangePasswordDialog({
    this.isForced = false,
    this.pointColor = AppTheme.primaryColor, // 기본값
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // 내부 팝업 (성공/실패 메시지)
  void _showPopupDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? Colors.redAccent : widget.pointColor, // 아이콘도 팀 컬러로
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty) {
      _showPopupDialog("입력 오류", "모든 필드를 입력해주세요.", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showPopupDialog("비밀번호 오류", "새 비밀번호는 6자 이상이어야 합니다.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final error = await SupabaseRepository().changePassword(
      currentPassword: current,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.of(context).pop();
      // 성공 팝업
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: widget.pointColor, size: 48), // 팀 컬러 적용
                    const SizedBox(height: 20),
                    const Text("변경 완료", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text("비밀번호가 성공적으로 변경되었습니다.", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
                        child: const Text("확인"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      });
    } else {
      _showPopupDialog("변경 실패", error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // [강제 변경 시] 팀 컬러로 테두리 강조
        side: widget.isForced ? BorderSide(color: widget.pointColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "비밀번호 변경",
                  style: TextStyle(color: widget.pointColor, fontSize: 20, fontWeight: FontWeight.bold), // 팀 컬러 제목
                ),
                if (!widget.isForced)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  )
              ],
            ),
            if (widget.isForced) ...[
              const SizedBox(height: 8),
              const Text("임시 비밀번호로 로그인하셨습니다.\n보안을 위해 비밀번호를 변경해주세요.",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ],
            const SizedBox(height: 24),
            _buildTextField("현재 비밀번호 (임시 비밀번호)", _currentPasswordController),
            const SizedBox(height: 16),
            _buildTextField("새로운 비밀번호", _newPasswordController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.pointColor, // 팀 컬러 버튼
                  foregroundColor: Colors.white, // 텍스트 가시성을 위해 흰색 고정 (혹은 검정)
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text("변경하기", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class AppTheme {
  static const primaryColor = Color(0xFF6C63FF);
}