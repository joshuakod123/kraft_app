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
    _initialize();
    return AuthStatus.initial;
  }

  Future<void> _initialize() async {
    // 스플래시 애니메이션 시간 확보 (2.5초) + 세션 확인
    await Future.wait([
      _restoreSession(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);
  }

  Future<void> _restoreSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _checkProfile();
        return;
      }
    } catch (e) {
      // 에러 시 비로그인 처리
    }
    state = AuthStatus.unauthenticated;
  }

  Future<void> _checkProfile() async {
    final profile = await _repo.getUserProfile();
    // 정보가 없거나, 필수 정보(이름 등)가 누락되었으면 온보딩으로 보냄
    if (profile == null || profile['name'] == null || profile['team_id'] == null) {
      state = AuthStatus.onboardingRequired;
    } else {
      _setGlobalState(profile);
      state = AuthStatus.authenticated;
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
    await _checkProfile();
  }

  Future<void> signUp(String email, String password) async {
    final error = await _repo.signUp(email: email, password: password);
    if (error != null) throw error;
    // 회원가입 직후엔 프로필이 없으므로 로그인 성공 시 자동으로 온보딩으로 이동됨
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
      ref.read(currentDeptProvider.notifier).setDept(dept);
      state = AuthStatus.authenticated;
    } else {
      throw "프로필 저장에 실패했습니다.";
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);