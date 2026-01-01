import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart'; // 추가됨
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';
// 기타 import...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase 초기화 (기존 코드가 있다면 Key 확인 필수)
  await Supabase.initialize(
    url: 'https://sipcistijzrouecclncj.supabase.co', // 실제 URL로 교체하세요
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpcGNpc3Rpanpyb3VlY2NsbmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjc5OTIsImV4cCI6MjA3OTY0Mzk5Mn0.M9wyquasQNJy9Ri4C5Zl-ncqYt2ghPiCF4F-6iQLJK0', // 실제 KEY로 교체하세요
  );

  // 2. [필수] 오디오 백그라운드 재생 초기화
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Kraft App',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}