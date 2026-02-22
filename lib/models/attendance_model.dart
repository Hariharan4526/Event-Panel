class AttendanceModel {
  final String id;
  final String userId;
  final String eventId;
  final String scannedBy;
  final DateTime scannedAt;

  // Additional fields from joins
  String? userName;
  String? userEmail;
  String? eventTitle;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.scannedBy,
    required this.scannedAt,
    this.userName,
    this.userEmail,
    this.eventTitle,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      scannedBy: json['scanned_by'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      eventTitle: json['event_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'scanned_by': scannedBy,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }
}

