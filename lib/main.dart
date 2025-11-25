import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/state/global_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Supabase 설정 (본인의 URL/KEY 입력)
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_KEY',
  // );

  runApp(const ProviderScope(child: KraftApp()));
}

class KraftApp extends ConsumerWidget {
  const KraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 선택된 부서(Team) 상태 감지
    final currentDept = ref.watch(currentDeptProvider);

    return MaterialApp.router(
      title: 'KRAFT',
      debugShowCheckedModeBanner: false,

      // Dynamic Theme 적용 (팀 컬러 반영)
      theme: AppTheme.getDynamicTheme(currentDept),

      // GoRouter 연결
      routerConfig: appRouter,
    );
  }
}