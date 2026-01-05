import 'package:intl/intl.dart';

class KraftDateUtils {
  // 날짜 포맷팅 (예: 2024.03.15 Fri)
  static String formatTaskDate(DateTime date) {
    return DateFormat('yyyy.MM.dd EEE', 'ko_KR').format(date);
  }

  // D-Day 계산
  static String getDday(DateTime deadline) {
    final now = DateTime.now();
    final dateOnlyDeadline = DateTime(deadline.year, deadline.month, deadline.day);
    final dateOnlyNow = DateTime(now.year, now.month, now.day);

    final difference = dateOnlyDeadline.difference(dateOnlyNow).inDays;

    if (difference < 0) return 'END';
    if (difference == 0) return 'D-Day';
    return 'D-$difference';
  }

  // [필수 추가] 캘린더용 날짜 정규화 (시분초 제거)
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}