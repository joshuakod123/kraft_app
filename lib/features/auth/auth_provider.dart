import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/data/supabase_repository.dart';

// 인증 상태 열거형
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  onboardingRequired,
}

// 인증 상태 관리 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier() : super(AuthStatus.initial) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = AuthStatus.unauthenticated;
    } else {
      await _checkOnboarding();
    }

    // Auth 상태 변경 감지
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await _checkOnboarding();
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthStatus.unauthenticated;
      }
    });
  }

  Future<void> _checkOnboarding() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = AuthStatus.unauthenticated;
      return;
    }

    // DB에서 유저 정보 확인
    final userData = await SupabaseRepository().getUserProfile();

    // 이름이 없으면 온보딩 필요
    if (userData == null || userData['name'] == null || userData['name'].isEmpty) {
      state = AuthStatus.onboardingRequired;
    } else {
      state = AuthStatus.authenticated;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = AuthStatus.unauthenticated;
  }
}

// [핵심] ProfileScreen에서 사용하는 유저 데이터 Provider
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // 인증 상태가 변경될 때마다 다시 로드
  ref.watch(authProvider);
  return SupabaseRepository().getUserProfile();
});

// 관리자 여부 확인 Provider
final isManagerProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userDataProvider);
  return userAsync.when(
    data: (user) => user?['role'] == 'manager' || user?['role'] == 'executive',
    loading: () => false,
    error: (_, __) => false,
  );
});