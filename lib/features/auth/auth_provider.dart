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
    // [중요] 빌드 즉시 초기화 로직 시작
    Future.microtask(() => _initialize());
    // [중요] 로직이 끝날 때까지는 무조건 'initial' 상태 유지 -> 라우터가 스플래시만 보여주게 됨
    return AuthStatus.initial;
  }

  Future<void> _initialize() async {
    // 1. 스플래시 화면을 볼 시간을 확보 (2.5초 대기)
    //    이 대기 시간이 없으면 앱이 너무 빨리 로딩되어 스플래시가 번쩍하고 사라집니다.
    await Future.delayed(const Duration(milliseconds: 2500));

    // 2. 대기 후 세션 체크 시작
    await _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final profile = await _repo.getUserProfile();
        // 프로필이 없거나 필수 정보가 비어있으면 -> 온보딩으로
        if (profile == null || profile['name'] == null || profile['team_id'] == null) {
          state = AuthStatus.onboardingRequired;
        } else {
          // 정보가 다 있으면 -> 메인 홈으로
          _setGlobalState(profile);
          state = AuthStatus.authenticated;
        }
      } else {
        // 세션이 없으면 -> 로그인 화면으로
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