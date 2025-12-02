import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/data/supabase_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, onboardingRequired }

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

  void logout() {}
}

// [필수] ProfileScreen 에러 해결용 Provider
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authProvider);
  return SupabaseRepository().getUserProfile();
});

final isManagerProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userDataProvider);
  return userAsync.maybeWhen(
    data: (user) => user?['role'] == 'manager',
    orElse: () => false,
  );
});