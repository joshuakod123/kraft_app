import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_kit/glass_kit.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true; // 로그인 vs 회원가입 모드
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await ref.read(authProvider.notifier).login(email, password);
      } else {
        await ref.read(authProvider.notifier).signUp(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')));
          setState(() => _isLoginMode = true); // 가입 후 로그인 모드로 전환
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/logo.png'), // 배경 이미지가 있다면 교체
            fit: BoxFit.cover,
            opacity: 0.2, // 어둡게 처리
          ),
          color: Colors.black,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'KRAFT',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8
                  ),
                ).animate().fadeIn().moveY(begin: -20, end: 0),
                const SizedBox(height: 50),

                GlassContainer.clearGlass(
                  height: 400,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(20),
                  borderWidth: 1.0,
                  borderColor: Colors.white.withValues(alpha: 0.3),
                  elevation: 10,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoginMode ? 'MEMBER LOGIN' : 'JOIN KRAFT',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.email, color: Colors.white),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(_isLoginMode ? 'ENTER' : 'SIGN UP', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                        child: Text(
                          _isLoginMode ? 'Create an account' : 'Already have an account?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}