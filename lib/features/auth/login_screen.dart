import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // [배경] 움직이는 네온 오브젝트
          Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withValues(alpha: 0.4), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.purpleAccent)])))
              .animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 4.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          Positioned(bottom: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.3), boxShadow: [const BoxShadow(blurRadius: 150, color: Colors.cyanAccent)])))
              .animate(onPlay: (c) => c.repeat(reverse: true)).moveY(duration: 5.seconds, begin: 0, end: 50),

          // [메인 폼]
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
                    height: 520,
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
                        const SizedBox(height: 20),

                        // [로그인 유지 버튼]
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

extension on AuthNotifier {
  signUp(String trim, String trim2) {}

  login(String trim, String trim2) {}
}