class RegistrationModel {
  final String id;
  final String userId;
  final String eventId;
  final String paymentStatus; // 'pending', 'completed', 'failed', 'refunded'
  final double amountPaid;
  final String qrToken;
  final DateTime createdAt;

  // Additional fields from joins
  String? userName;
  String? userEmail;
  String? eventTitle;
  DateTime? eventStartDate;
  String? eventVenue;

  RegistrationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.paymentStatus,
    required this.amountPaid,
    required this.qrToken,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.eventTitle,
    this.eventStartDate,
    this.eventVenue,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      paymentStatus: json['payment_status'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      qrToken: json['qr_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      eventTitle: json['event_title'] as String?,
      eventStartDate: json['event_start_date'] != null
          ? DateTime.parse(json['event_start_date'] as String)
          : null,
      eventVenue: json['event_venue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'qr_token': qrToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPaid => paymentStatus == 'completed';
  bool get isPending => paymentStatus == 'pending';
  bool get isFailed => paymentStatus == 'failed';
}

