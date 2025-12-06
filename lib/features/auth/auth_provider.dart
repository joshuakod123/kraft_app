import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/data/supabase_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, onboardingRequired }

// [수정] StateNotifierProvider 사용 (가장 안정적이고 익숙한 방식)
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

    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await _checkOnboarding();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = AuthStatus.unauthenticated;
      }
    });
  }

  Future<void> _checkOnboarding() async {
    final userData = await SupabaseRepository().getUserProfile();
    // 이름이 없으면 온보딩 필요
    if (userData == null || userData['name'] == null) {
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
  ref.watch(authProvider); // 로그인 상태가 바뀌면 다시 로드
  return SupabaseRepository().getUserProfile();
});

// 관리자 여부 확인
final isManagerProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userDataProvider);
  return userAsync.maybeWhen(
    data: (user) => user?['role'] == 'manager' || user?['role'] == 'executive',
    orElse: () => false,
  );
});