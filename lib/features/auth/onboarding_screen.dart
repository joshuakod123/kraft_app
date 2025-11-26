import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // go_router import 필수
import '../../core/constants/department_enum.dart';
import 'auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Department? _selectedDept;
  bool _isLoading = false;

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate() || _selectedDept == null) {
      if (_selectedDept == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('소속 팀을 선택해주세요.')));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 프로필 업데이트 요청
      await ref.read(authProvider.notifier).completeOnboarding(
        name: _nameCtrl.text.trim(),
        studentId: _studentIdCtrl.text.trim(),
        major: _majorCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dept: _selectedDept!,
      );

      // 2. [핵심 수정] 성공 시 강제로 홈으로 이동 (Router가 반응하기 전에 먼저 보냄)
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // 실패 시 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("정보 입력", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(authProvider.notifier).logout(); // 뒤로가기 시 로그아웃
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("환영합니다! 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("원활한 활동을 위해 기본 정보를 입력해주세요.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 30),
              _buildField("이름 (Name)", _nameCtrl),
              _buildField("학번 (Student ID)", _studentIdCtrl),
              _buildField("학과 (Major)", _majorCtrl),
              _buildField("전화번호 (Phone)", _phoneCtrl),
              const SizedBox(height: 20),
              DropdownButtonFormField<Department>(
                dropdownColor: Colors.grey[900],
                value: _selectedDept,
                hint: const Text("소속 팀 선택", style: TextStyle(color: Colors.grey)),
                items: Department.values.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept.name, style: TextStyle(color: dept.color)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDept = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _complete,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("START KRAFT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (val) => val == null || val.isEmpty ? '필수 입력입니다.' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}