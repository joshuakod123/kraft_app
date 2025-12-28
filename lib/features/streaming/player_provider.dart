import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// [중요] 현재 재생 중인 곡을 관리하는 변수입니다.
final currentSongProvider = StateProvider<MediaItem?>((ref) => null);

// 플레이어가 전체 화면인지 미니 모드인지 관리하는 변수입니다.
final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);