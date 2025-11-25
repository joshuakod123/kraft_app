import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase 설정 시 주석 해제
import 'core/router/app_router.dart';
import 'core/state/global_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화 코드는 나중에 키를 넣고 주석 해제하세요.
  // await Supabase.initialize(...);

  runApp(const ProviderScope(child: KraftApp()));
}

class KraftApp extends ConsumerWidget {
  const KraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDept = ref.watch(currentDeptProvider);

    // [수정됨] routerProvider를 watch하여 라우터 설정 가져오기
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KRAFT App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getDynamicTheme(currentDept),

      // GoRouter 연결
      routerConfig: router,
    );
  }
}