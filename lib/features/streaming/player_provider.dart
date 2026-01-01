import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

// 현재 재생 중인 곡을 담는 그릇 (초기값: 없음)
final currentSongProvider = StateProvider<MediaItem?>((ref) => null);

// 플레이어가 커진 상태인지(전체화면) 작아진 상태인지(미니) 관리
final isPlayerExpandedProvider = StateProvider<bool>((ref) => false);