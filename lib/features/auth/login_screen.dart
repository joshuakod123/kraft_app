import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart'; // Department enum import 필수
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
  bool _isLogin = true;
  bool _isLoading = false;
  bool _keepLoggedIn = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _pwCtrl.text.trim());
      } else {
        await ref.read(authProvider.notifier).signUp(_emailCtrl.text.trim(), _pwCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입 성공! 로그인해주세요.'), backgroundColor: Colors.green));
          setState(() => _isLogin = true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [Modified] 비밀번호 찾기 다이얼로그 (팀 컬러 반영)
  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isDialogLoading = false;

    // 결과값 저장용
    String? tempPasswordResult;
    Color? teamColorResult; // 팀 색상 저장

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 결과가 있으면 그 색상, 없으면 기본 Cyan
            final activeColor = teamColorResult ?? Colors.cyanAccent;

            return Dialog(
              backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: activeColor.withOpacity(0.5), width: 1.5) // 테두리 색상 동적 변경
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: tempPasswordResult != null
                // [Step 2] 결과 화면 (동적 컬러 적용)
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_reset, color: activeColor, size: 48),
                    const SizedBox(height: 16),
                    Text("임시 비밀번호 발급", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text("아래 비밀번호로 로그인해주세요.\n로그인 후 즉시 비밀번호 변경창이 뜹니다.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: activeColor),
                      ),
                      child: SelectableText(
                        tempPasswordResult!,
                        style: TextStyle(color: activeColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tempPasswordResult!));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("비밀번호가 복사되었습니다."), backgroundColor: activeColor));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: activeColor, foregroundColor: Colors.black),
                        child: const Text("복사하고 닫기", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
                // [Step 1] 입력 화면 (기본 Cyan)
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Forgot Password?", style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("가입된 정보를 입력하면 임시 비밀번호를 발급합니다.", style: TextStyle(color: Colors.white54, fontSize: 13)),
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
                        onPressed: isDialogLoading
                            ? null
                            : () async {
                          final email = emailCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();

                          if (email.isEmpty || name.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 정보를 입력해주세요.")));
                            return;
                          }

                          setStateDialog(() => isDialogLoading = true);

                          // Repository 호출 (Map 반환)
                          final result = await SupabaseRepository().requestTemporaryPassword(
                            email: email,
                            name: name,
                            phone: phone,
                          );

                          setStateDialog(() {
                            isDialogLoading = false;
                            if (result != null) {
                              tempPasswordResult = result['password'];
                              // Team ID로 색상 찾기
                              final teamId = result['team_id'] as int? ?? 1;
                              teamColorResult = Department.values.firstWhere(
                                      (d) => d.id == teamId,
                                  orElse: () => Department.business
                              ).color;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일치하는 회원 정보가 없습니다.")));
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isDialogLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text("임시 비밀번호 발급", style: TextStyle(fontWeight: FontWeight.bold)),
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
            isDense: true,
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... 기존 build 코드와 동일 (유지) ...
    // (이전 답변의 LoginScreen build와 동일하므로 생략하지 않고 전체가 필요하면 이전 코드 복사 후 _showForgotPasswordDialog만 교체하세요.
    // 편의상 이 블록 안에는 핵심 변경 사항인 _showForgotPasswordDialog가 중요합니다.)
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withValues(alpha: 0.4), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.purpleAccent)])))
              .animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          Positioned(bottom: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.3), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.cyanAccent)])))
              .animate(onPlay: (c) => c.repeat(reverse: true)).moveY(duration: 5.seconds, begin: 0, end: 50),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.movie_filter, size: 60, color: Colors.white).animate().fadeIn().scale(),
                  const SizedBox(height: 10),
                  Text('KRAFT', style: GoogleFonts.chakraPetch(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6)).animate().fadeIn().moveY(begin: -20, end: 0),
                  Text('MEDIA & ENTERTAINMENT', style: GoogleFonts.inter(color: Colors.white70, letterSpacing: 2, fontSize: 12)).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 50),

                  GlassContainer.clearGlass(
                    height: 540,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(24),
                    borderWidth: 1.5,
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    elevation: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLogin ? 'MEMBER LOGIN' : 'JOIN THE CREW', style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 30),
                        _buildTextField(_emailCtrl, 'Email', Icons.email_outlined, false),
                        const SizedBox(height: 16),
                        _buildTextField(_pwCtrl, 'Password', Icons.lock_outline, true),

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7), fontSize: 12),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        if (_isLogin)
                          Row(
                            children: [
                              SizedBox(
                                width: 24, height: 24,
                                child: Checkbox(
                                  value: _keepLoggedIn,
                                  activeColor: Colors.cyanAccent,
                                  checkColor: Colors.black,
                                  side: const BorderSide(color: Colors.white54),
                                  onChanged: (val) => setState(() => _keepLoggedIn = val!),
                                ),
                              ),
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
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? "New here? Sign Up" : "Have account? Login", style: const TextStyle(color: Colors.white70)),
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
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: ctrl, obscureText: obscure, style: const TextStyle(color: Colors.white), cursorColor: Colors.cyanAccent,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38), prefixIcon: Icon(icon, color: Colors.white70), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }
}