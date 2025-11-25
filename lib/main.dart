import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // import 필수
import 'core/router/app_router.dart';
import 'core/state/global_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [중요] Supabase 프로젝트 설정값 입력
  await Supabase.initialize(
    url: 'https://sipcistijzrouecclncj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpcGNpc3Rpanpyb3VlY2NsbmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjc5OTIsImV4cCI6MjA3OTY0Mzk5Mn0.M9wyquasQNJy9Ri4C5Zl-ncqYt2ghPiCF4F-6iQLJK0',
  );

  runApp(const ProviderScope(child: KraftApp()));
}

class KraftApp extends ConsumerWidget {
  const KraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDept = ref.watch(currentDeptProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KRAFT App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getDynamicTheme(currentDept),
      routerConfig: router,
    );
  }
}