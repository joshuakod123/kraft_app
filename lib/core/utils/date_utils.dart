import 'package:intl/intl.dart';

class KraftDateUtils {
  // 날짜 포맷팅 (예: 2024.03.15 Fri)
  static String formatTaskDate(DateTime date) {
    return DateFormat('yyyy.MM.dd EEE').format(date);
  }

  // D-Day 계산 (마감일 - 현재시간)
  static String getDday(DateTime deadline) {
    final now = DateTime.now();
    // 시간, 분, 초를 제거하고 날짜만 비교하기 위해
    final dateOnlyDeadline = DateTime(deadline.year, deadline.month, deadline.day);
    final dateOnlyNow = DateTime(now.year, now.month, now.day);

    final difference = dateOnlyDeadline.difference(dateOnlyNow).inDays;

    if (difference < 0) return 'END';
    if (difference == 0) return 'D-Day';
    return 'D-$difference';
  }
}