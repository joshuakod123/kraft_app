class AttendanceLog {
  final int id;
  final String userId;
  final String teamName;
  final String sessionName;
  final DateTime createdAt;

  AttendanceLog({
    required this.id,
    required this.userId,
    required this.teamName,
    required this.sessionName,
    required this.createdAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      teamName: json['team_name'] ?? '소속 없음',
      sessionName: json['session_name'] ?? '세션 정보 없음',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}