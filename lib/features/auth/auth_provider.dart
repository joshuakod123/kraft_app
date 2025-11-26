import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';

enum AuthStatus { initial, unauthenticated, onboardingRequired, authenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  final _repo = SupabaseRepository();

  @override
  AuthStatus build() {
    Future.microtask(() => _initialize());
    return AuthStatus.initial;
  }

  Future<void> _initialize() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _checkSession(),
    ]);
  }

  Future<void> _checkSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final profile = await _repo.getUserProfile();
        if (profile == null || profile['name'] == null || profile['team_id'] == null) {
          state = AuthStatus.onboardingRequired;
        } else {
          _setGlobalState(profile);
          state = AuthStatus.authenticated;
        }
      } else {
        state = AuthStatus.unauthenticated;
      }
    } catch (e) {
      state = AuthStatus.unauthenticated;
    }
  }

  void _setGlobalState(Map<String, dynamic> profile) {
    final teamId = profile['team_id'] as int?;
    final dept = Department.values.firstWhere(
          (d) => d.id == teamId,
      orElse: () => Department.business,
    );

    ref.read(currentDeptProvider.notifier).setDept(dept);
    ref.read(isManagerProvider.notifier).setManager(profile['role'] == 'manager');
  }

  Future<void> login(String email, String password) async {
    final error = await _repo.signIn(email: email, password: password);
    if (error != null) throw error;
    await _checkSession();
  }

  Future<void> signUp(String email, String password) async {
    final error = await _repo.signUp(email: email, password: password);
    if (error != null) throw error;
  }

  Future<void> completeOnboarding({
    required String name,
    required String studentId,
    required String major,
    required String phone,
    required Department dept,
  }) async {
    final success = await _repo.updateUserProfile(
      name: name,
      studentId: studentId,
      major: major,
      phone: phone,
      teamId: dept.id,
    );

    if (success) {
      // 전역 상태 설정
      ref.read(currentDeptProvider.notifier).setDept(dept);
      // 상태 변경 (Router가 감지)
      state = AuthStatus.authenticated;
    } else {
      // 실패 시 에러 throw -> OnboardingScreen에서 catch함
      throw "프로필 저장 중 오류가 발생했습니다. DB 연결을 확인하세요.";
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);