import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 현재 선택된(재생 중인) 곡 정보
final currentSongProvider = StateProvider<MediaItem?>((ref) => null);

// 플레이어 UI가 전체 화면인지 여부
final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);