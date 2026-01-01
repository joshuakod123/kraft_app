class AttendanceLog {
  final int attendanceId;
  final String userName;
  final String teamName;
  final String sessionId;
  final DateTime createdAt;

  AttendanceLog({
    required this.attendanceId,
    required this.userName,
    required this.teamName,
    required this.sessionId,
    required this.createdAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      attendanceId: json['attendance_id'] ?? 0,
      userName: json['user_name'] ?? '알 수 없음',
      teamName: json['team_name'] ?? '소속 없음',
      sessionId: json['session_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}