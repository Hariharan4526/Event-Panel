class EventModel {
  final String id;
  final String title;
  final String description;
  final String? bannerUrl;
  final String category; // 'academic', 'social', 'sport'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final String venue;
  final int maxCapacity;
  final double price;
  final String createdBy;
  final String status; // 'draft', 'published', 'cancelled', 'completed'
  final DateTime createdAt;
  final bool allowWaitlist;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.bannerUrl,
    required this.category,
    required this.startDate,
    this.endDate,
    this.registrationDeadline,
    required this.venue,
    required this.maxCapacity,
    required this.price,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.allowWaitlist = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      bannerUrl: json['banner_url'] as String?,
      category: json['category'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      venue: json['venue'] as String,
      maxCapacity: json['max_capacity'] as int,
      price: (json['price'] as num).toDouble(),
      createdBy: json['created_by'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      allowWaitlist: json['allow_waitlist'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'banner_url': bannerUrl,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'venue': venue,
      'max_capacity': maxCapacity,
      'price': price,
      'created_by': createdBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'allow_waitlist': allowWaitlist,
    };
  }

  bool get isFree => price == 0;
  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'academic':
        return '📚';
      case 'social':
        return '🎉';
      case 'sport':
        return '⚽';
      default:
        return '📅';
    }
  }
}

