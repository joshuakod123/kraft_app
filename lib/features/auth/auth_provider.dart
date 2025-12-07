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
    // 앱 시작 시 무조건 초기화 로직 실행
    Future.microtask(() => _initialize());
    return AuthStatus.initial; // 초기 상태는 무조건 Loading
  }

  Future<void> _initialize() async {
    // 2.5초 대기와 세션 체크를 병렬로 실행하되, 둘 다 끝날 때까지 대기
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
        // 정보가 없으면 온보딩
        if (profile == null || profile['name'] == null || profile['team_id'] == null) {
          state = AuthStatus.onboardingRequired;
        } else {
          // 정보가 있으면 홈으로
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

    // 전역 상태 설정
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
    required String major,
    required String phone,
    required Department dept,
    required String school,
    required String studentId,
    required String gender,
  }) async {
    final success = await _repo.updateUserProfile(
      name: name,
      major: major,
      phone: phone,
      teamId: dept.id,
      school: school,
      studentId: studentId,
      gender: gender,
    );

    if (success) {
      ref.read(currentDeptProvider.notifier).setDept(dept);
      state = AuthStatus.authenticated;
    } else {
      throw "프로필 저장 실패";
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);