class AttendanceLog {
  final int id;
  final String userId;
  final int curriculumId;
  final int teamId;
  final String status;
  final DateTime createdAt;

  AttendanceLog({
    required this.id,
    required this.userId,
    required this.curriculumId,
    required this.teamId,
    required this.status,
    required this.createdAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      curriculumId: json['curriculum_id'] ?? 0,
      teamId: json['team_id'] ?? 0,
      status: json['status'] ?? 'present',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}