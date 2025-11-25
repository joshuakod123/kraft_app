import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate() || _selectedDept == null) {
      if (_selectedDept == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('소속 팀을 선택해주세요.')));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).completeOnboarding(
        name: _nameCtrl.text,
        studentId: _studentIdCtrl.text,
        major: _majorCtrl.text,
        phone: _phoneCtrl.text,
        dept: _selectedDept!,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("WELCOME MEMBER"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("기본 정보를 입력해주세요.", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              _buildTextField("이름 (Name)", _nameCtrl),
              _buildTextField("학번 (Student ID)", _studentIdCtrl),
              _buildTextField("학과 (Major)", _majorCtrl),
              _buildTextField("전화번호 (Phone)", _phoneCtrl),

              const SizedBox(height: 20),
              const Text("소속 팀 (Team)", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 10),
              DropdownButtonFormField<Department>(
                dropdownColor: Colors.grey[900],
                value: _selectedDept,
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
                  onPressed: _isLoading ? null : _completeOnboarding,
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

  Widget _buildTextField(String label, TextEditingController controller) {
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