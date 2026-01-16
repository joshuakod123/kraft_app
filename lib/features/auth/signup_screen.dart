import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/data/supabase_repository.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _majorController = TextEditingController();
  final _schoolController = TextEditingController();

  // 기수 선택 (Dropdown)
  int _selectedCohort = 1;

  bool _isLoading = false;

  // [수정 12] 에러/성공 팝업 함수
  void _showPopup(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: isSuccess ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) context.go('/login'); // 성공 시 로그인 화면으로
            },
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseRepository().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedCohort,
        _majorController.text.trim(),
        _schoolController.text.trim(),
        _studentIdController.text.trim(),
      );
      if (!mounted) return;
      _showPopup("회원가입 성공", "회원가입이 완료되었습니다.\n로그인해주세요.", isSuccess: true);
    } on AuthException catch (e) {
      _showPopup("오류", e.message);
    } catch (e) {
      _showPopup("오류", "알 수 없는 오류가 발생했습니다: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // [수정 9] 뒤로가기 버튼을 위한 AppBar 추가
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("JOIN KRAFT", style: GoogleFonts.chakraPetch(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),

              _buildTextField("이메일", _emailController),
              const SizedBox(height: 16),
              _buildTextField("비밀번호", _passwordController, obscureText: true),
              const SizedBox(height: 16),
              _buildTextField("이름", _nameController),
              const SizedBox(height: 16),

              // 기수 선택 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCohort,
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e, child: Text("$e기"))).toList(),
                    onChanged: (val) => setState(() => _selectedCohort = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("학교", _schoolController),
              const SizedBox(height: 16),
              _buildTextField("전공", _majorController),
              const SizedBox(height: 16),
              _buildTextField("학번", _studentIdController),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("회원가입", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}