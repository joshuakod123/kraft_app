import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../core/data/supabase_repository.dart';

// 인증 상태: Unauthenticated, OnboardingRequired, Authenticated
enum AuthStatus { unauthenticated, onboardingRequired, authenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  final _repo = SupabaseRepository();

  @override
  AuthStatus build() {
    _restoreSession();
    return AuthStatus.unauthenticated;
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _checkProfile();
    }
  }

  Future<void> _checkProfile() async {
    final profile = await _repo.getUserProfile();
    if (profile == null) {
      // 로그인은 됐는데 DB에 정보가 없음 -> 온보딩 필요
      state = AuthStatus.onboardingRequired;
    } else {
      // 정보가 있음 -> 메인으로
      _setGlobalState(profile);
      state = AuthStatus.authenticated;
    }
  }

  void _setGlobalState(Map<String, dynamic> profile) {
    final teamId = profile['team_id'] as int?;
    final dept = Department.values.firstWhere(
            (d) => d.id == teamId,
        orElse: () => Department.business
    );

    ref.read(currentDeptProvider.notifier).setDept(dept);
    ref.read(isManagerProvider.notifier).setManager(profile['role'] == 'manager');
    // 사용자 이름 저장 (임시로 isManagerProvider 옆에 저장하거나 별도 Provider 필요)
    // 여기선 간단히 ref.read를 통해 어딘가 저장했다고 가정하거나, DB에서 매번 불러올 수도 있음
  }

  Future<void> login(String email, String password) async {
    final error = await _repo.signIn(email: email, password: password);
    if (error != null) throw error;
    await _checkProfile();
  }

  Future<void> signUp(String email, String password) async {
    final error = await _repo.signUp(email: email, password: password);
    if (error != null) throw error;
    // 회원가입 직후에는 프로필이 없으므로 온보딩으로 가야 함 (로그인 되면)
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
      // 전역 상태 갱신
      ref.read(currentDeptProvider.notifier).setDept(dept);
      state = AuthStatus.authenticated;
    } else {
      throw "Failed to update profile";
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);