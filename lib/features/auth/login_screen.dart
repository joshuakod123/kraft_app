import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/data/supabase_repository.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  // true: 로그인 모드, false: 회원가입 모드
  bool _isLogin = true;
  bool _isLoading = false;
  bool _keepLoggedIn = true;

  // [Feedback 12] 에러 팝업 (SnackBar 대신 Dialog 사용)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 1.5)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Text("오류", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // [Feedback 12] 성공 팝업
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent, width: 1.5)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Text("성공", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("확인", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _pwCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("이메일과 비밀번호를 모두 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).login(email, password);
      } else {
        await ref.read(authProvider.notifier).signUp(email, password);
        if (mounted) {
          _showSuccessDialog('가입 성공! 로그인해주세요.');
          setState(() => _isLogin = true); // 가입 성공 시 로그인 화면으로 전환
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.contains("Invalid login credentials")) {
        errorMessage = "이메일 또는 비밀번호가 올바르지 않습니다.";
      } else if (errorMessage.contains("Email not confirmed")) {
        errorMessage = "이메일 인증이 완료되지 않았습니다.";
      } else if (errorMessage.contains("User already registered")) {
        errorMessage = "이미 가입된 이메일입니다.";
      } else {
        errorMessage = errorMessage.replaceAll("Exception: ", "");
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    // (기존 코드 유지 - 너무 길어서 생략하지만, 필요하다면 그대로 두시면 됩니다)
    // ... 기존과 동일 ...
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isDialogLoading = false;
    String? tempPasswordResult;
    Color? teamColorResult;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final activeColor = teamColorResult ?? Colors.cyanAccent;
            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: activeColor.withOpacity(0.5), width: 1.5)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: tempPasswordResult != null
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_reset, color: activeColor, size: 48),
                    const SizedBox(height: 16),
                    Text("임시 비밀번호 발급", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text("아래 비밀번호로 로그인해주세요.\n로그인 후 즉시 비밀번호 변경창이 뜹니다.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: activeColor)),
                      child: SelectableText(tempPasswordResult!, style: TextStyle(color: activeColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () { Clipboard.setData(ClipboardData(text: tempPasswordResult!)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("비밀번호가 복사되었습니다."), backgroundColor: activeColor)); },
                        style: ElevatedButton.styleFrom(backgroundColor: activeColor, foregroundColor: Colors.black),
                        child: const Text("복사하고 닫기", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Forgot Password?", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildDialogTextField("이메일", emailCtrl),
                    const SizedBox(height: 12),
                    _buildDialogTextField("이름", nameCtrl),
                    const SizedBox(height: 12),
                    _buildDialogTextField("전화번호 (숫자만)", phoneCtrl, isNumber: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isDialogLoading ? null : () async {
                          final email = emailCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          if (email.isEmpty || name.isEmpty || phone.isEmpty) return;
                          setStateDialog(() => isDialogLoading = true);
                          final result = await SupabaseRepository().requestTemporaryPassword(email: email, name: name, phone: phone);
                          setStateDialog(() {
                            isDialogLoading = false;
                            if (result != null) {
                              tempPasswordResult = result['password'];
                              final teamId = result['team_id'] as int? ?? 1;
                              teamColorResult = Department.values.firstWhere((d) => d.id == teamId, orElse: () => Department.business).color;
                            } else {
                              // 여기는 Dialog 내부라 SnackBar 사용해도 무방하지만 일관성을 위해 텍스트 표시 등으로 바꿀 수 있음
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일치하는 회원 정보가 없습니다.")));
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isDialogLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("임시 비밀번호 발급", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true, filled: true, fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // [Feedback 9] 안드로이드 물리 뒤로가기 버튼 처리
    return PopScope(
      canPop: _isLogin, // 로그인 모드일 때만 앱 종료 가능
      onPopInvoked: (didPop) {
        if (!didPop && !_isLogin) {
          // 회원가입 모드에서 뒤로가기 누르면 로그인 모드로 전환
          setState(() => _isLogin = true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(0.4), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.purpleAccent)])))
                .animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
            Positioned(bottom: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withOpacity(0.3), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.cyanAccent)])))
                .animate(onPlay: (c) => c.repeat(reverse: true)).moveY(duration: 5.seconds, begin: 0, end: 50),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.movie_filter, size: 60, color: Colors.white).animate().fadeIn().scale(),
                    const SizedBox(height: 10),
                    Text('KRAFT', style: GoogleFonts.chakraPetch(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6)).animate().fadeIn().moveY(begin: -20, end: 0),
                    const SizedBox(height: 50),

                    GlassContainer.clearGlass(
                      height: 560, // 높이 약간 증가
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(24),
                      borderWidth: 1.5,
                      borderColor: Colors.white.withOpacity(0.2),
                      elevation: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // [Feedback 9] 상단 뒤로가기 아이콘 (회원가입 시 표시)
                              if (!_isLogin)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                                    onPressed: () => setState(() => _isLogin = true),
                                  ),
                                ),
                              Text(_isLogin ? 'MEMBER LOGIN' : 'JOIN THE CREW', style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildTextField(_emailCtrl, 'Email', Icons.email_outlined, false),
                          const SizedBox(height: 16),
                          _buildTextField(_pwCtrl, 'Password', Icons.lock_outline, true),

                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(padding: const EdgeInsets.only(top: 8, bottom: 8, left: 10), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text("Forgot Password?", style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7), fontSize: 12)),
                              ),
                            ),

                          const SizedBox(height: 12),
                          if (_isLogin)
                            Row(
                              children: [
                                SizedBox(width: 24, height: 24, child: Checkbox(value: _keepLoggedIn, activeColor: Colors.cyanAccent, checkColor: Colors.black, side: const BorderSide(color: Colors.white54), onChanged: (val) => setState(() => _keepLoggedIn = val!))),
                                const SizedBox(width: 8),
                                const Text("Keep me logged in", style: TextStyle(color: Colors.white70)),
                              ],
                            ).animate().fadeIn(),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(_isLogin ? 'ENTER' : 'SIGN UP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // [Feedback 9] 하단 전환 버튼
                          if (_isLogin)
                            TextButton(
                              onPressed: () => setState(() => _isLogin = !_isLogin),
                              child: const Text("New here? Sign Up", style: TextStyle(color: Colors.white70)),
                            )
                          else
                          // 회원가입 모드일 때 "로그인으로 돌아가기" 버튼 명시
                            TextButton(
                              onPressed: () => setState(() => _isLogin = true),
                              child: const Text("Already a member? Log in", style: TextStyle(color: Colors.white70)),
                            )
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: ctrl, obscureText: obscure, style: const TextStyle(color: Colors.white), cursorColor: Colors.cyanAccent,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38), prefixIcon: Icon(icon, color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }
}