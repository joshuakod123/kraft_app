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
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    _checkTempPasswordStatus();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = SupabaseRepository().getUserProfile();
    });
  }

  Future<void> _checkTempPasswordStatus() async {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final profile = await SupabaseRepository().getUserProfile();
      if (profile != null && profile['is_temp_password'] == true) {
        if (!mounted) return;
        final teamId = profile['team_id'] ?? 1;
        final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ChangePasswordDialog(
            isForced: true,
            pointColor: dept.color,
          ),
        );
      }
    });
  }

  void _showSettingsModal(BuildContext context, Map<String, dynamic> user, Department dept) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                _buildSettingsItem(
                  icon: Icons.edit_note_rounded,
                  text: "프로필 정보 수정",
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditProfileDialog(user, dept.color);
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.lock_reset_rounded,
                  text: "비밀번호 변경",
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => _ChangePasswordDialog(pointColor: dept.color),
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 30),
                _buildSettingsItem(
                  icon: Icons.logout_rounded,
                  text: "로그아웃",
                  color: Colors.white70,
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.person_remove_rounded,
                  text: "회원 탈퇴",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context, ref);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(Map<String, dynamic> user, Color pointColor) {
    final nameController = TextEditingController(text: user['name']);
    final majorController = TextEditingController(text: user['major']);
    final phoneController = TextEditingController(text: user['phone']);
    final schoolController = TextEditingController(text: user['school']);
    final studentIdController = TextEditingController(text: user['student_id']);

    final int teamId = user['team_id'];
    final String gender = user['gender'] ?? 'M';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("프로필 수정", style: TextStyle(color: pointColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField("이름", nameController),
              _buildEditTextField("학교", schoolController),
              _buildEditTextField("학번", studentIdController),
              _buildEditTextField("전공", majorController),
              _buildEditTextField("전화번호", phoneController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SupabaseRepository().updateUserProfile(
                  name: nameController.text,
                  major: majorController.text,
                  phone: phoneController.text,
                  teamId: teamId,
                  school: schoolController.text,
                  studentId: studentIdController.text,
                  gender: gender,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _refreshProfile();

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: pointColor, width: 1.5)
                      ),
                      title: const Text("수정 완료", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text("프로필 정보가 성공적으로 수정되었습니다.", style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("확인", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text("오류", style: TextStyle(color: Colors.redAccent)),
                      content: const Text("수정에 실패했습니다. 잠시 후 다시 시도해주세요.", style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("확인", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  );
                }
              }
            },
            child: Text("저장", style: TextStyle(color: pointColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('회원 탈퇴', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n계정 정보와 모든 활동 내역이 영구적으로 삭제됩니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) {
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  // 탈퇴 실패 시 한국어 에러
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('계정 탈퇴 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.')),
                  );
                }
              }
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
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

          final dept = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business);

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    SingleChildScrollView(
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
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (user != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
                          onPressed: () => _showSettingsModal(context, user, dept),
                        ),
                      ),
                  ],
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

class _ChangePasswordDialog extends StatefulWidget {
  final bool isForced;
  final Color pointColor;

  const _ChangePasswordDialog({
    this.isForced = false,
    this.pointColor = AppTheme.primaryColor,
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
                color: isError ? Colors.redAccent : widget.pointColor,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
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
    final error = await SupabaseRepository().changePassword(currentPassword: current, newPassword: newPass);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.of(context).pop();
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
                    Icon(Icons.check_circle_outline_rounded, color: widget.pointColor, size: 48),
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
                Text("비밀번호 변경", style: TextStyle(color: widget.pointColor, fontSize: 20, fontWeight: FontWeight.bold)),
                if (!widget.isForced)
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54))
              ],
            ),
            if (widget.isForced) ...[
              const SizedBox(height: 8),
              const Text("임시 비밀번호로 로그인하셨습니다.\n보안을 위해 비밀번호를 변경해주세요.", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  backgroundColor: widget.pointColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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