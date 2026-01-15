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

  // [디버깅] Step 1
  print('🚀 Step 1: 날짜 포맷팅 초기화 시작');
  await initializeDateFormatting('ko_KR', null);
  print('✅ Step 1 완료');

  // [디버깅] Step 2
  print('🚀 Step 2: Supabase 초기화 시작 (여기서 5초 이상 멈추면 에뮬레이터 인터넷 연결 문제!)');
  await Supabase.initialize(
    url: 'https://sipcistijzrouecclncj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpcGNpc3Rpanpyb3VlY2NsbmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjc5OTIsImV4cCI6MjA3OTY0Mzk5Mn0.M9wyquasQNJy9Ri4C5Zl-ncqYt2ghPiCF4F-6iQLJK0',
  );
  print('✅ Step 2 완료');

  // [디버깅] Step 3
  print('🚀 Step 3: 오디오 백그라운드 초기화 시작');
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  print('✅ Step 3 완료');

  // [디버깅] Step 4
  print('🚀 Step 4: 앱 실행(runApp) 시작! -> 이제 화면이 나와야 합니다.');
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