import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Intl 관련 import
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 날짜 포맷팅 초기화 (한국어 명시)
  // 에러가 계속 뜬다면 이 부분에 'ko_KR'을 명시하는 것이 가장 확실합니다.
  await initializeDateFormatting('ko_KR', null);

  // 2. Supabase 초기화
  await Supabase.initialize(
    url: 'https://sipcistijzrouecclncj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpcGNpc3Rpanpyb3VlY2NsbmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjc5OTIsImV4cCI6MjA3OTY0Mzk5Mn0.M9wyquasQNJy9Ri4C5Zl-ncqYt2ghPiCF4F-6iQLJK0',
  );

  // 3. 오디오 백그라운드 초기화
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