import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/department_enum.dart';
import 'auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러 정의
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();    // 학교
  final _studentIdCtrl = TextEditingController(); // 학번
  final _majorCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // 선택 값
  Department? _selectedDept;
  String? _selectedGender;

  bool _isLoading = false;

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate() || _selectedDept == null || _selectedGender == null) {
      if (_selectedDept == null || _selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모든 항목을 선택해주세요.'))
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).completeOnboarding(
        name: _nameCtrl.text.trim(),
        school: _schoolCtrl.text.trim(),
        studentId: _studentIdCtrl.text.trim(),
        major: _majorCtrl.text.trim(),
        gender: _selectedGender!,
        phone: _phoneCtrl.text.trim(),
        dept: _selectedDept!,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
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
        iconTheme: const IconThemeData(color: Colors.white),
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
              const Text("원활한 활동을 위해 상세 정보를 입력해주세요.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 30),

              _buildField("이름 (Name)", _nameCtrl),

              // [수정] 학교 & 학번 Row
              Row(
                children: [
                  Expanded(child: _buildField("대학교 (School)", _schoolCtrl)),
                  const SizedBox(width: 12),
                  // [수정] 학번 힌트 텍스트 추가 ("ex) 21학번")
                  Expanded(child: _buildField("학번 (Student ID)", _studentIdCtrl, isNumber: true, hintText: "ex) 21학번")),
                ],
              ),

              _buildField("학과 (Major)", _majorCtrl),

              // [수정] 성별 선택 (한국어 변경)
              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                value: _selectedGender,
                hint: const Text("성별 (Gender)", style: TextStyle(color: Colors.grey)),
                // [변경] Male/Female -> 남성/여성
                items: ['남성', '여성'].map((g) {
                  return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 16),

              _buildField("전화번호 (Phone)", _phoneCtrl, isNumber: true),

              const SizedBox(height: 16),
              DropdownButtonFormField<Department>(
                dropdownColor: Colors.grey[900],
                value: _selectedDept,
                hint: const Text("소속 팀 (Team)", style: TextStyle(color: Colors.grey)),
                items: Department.values.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept.name, style: TextStyle(color: dept.color)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDept = val),
                decoration: _inputDecoration(),
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
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // [수정] hintText 파라미터 추가
  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        validator: (val) => val == null || val.isEmpty ? '필수 입력입니다.' : null,
        // hintText 전달
        decoration: _inputDecoration().copyWith(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), // 힌트 색상 흐리게
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
      floatingLabelBehavior: FloatingLabelBehavior.auto, // 클릭 시 라벨 위로 이동 + 힌트 표시
    );
  }
}