enum NotificationType {
  orderUpdate('تحديث طلب'),
  newMessage('رسالة جديدة'),
  promotion('عرض جديد'),
  system('تنبيه نظام'),
  reviewRequest('طلب تقييم');

  final String label;
  const NotificationType(this.label);
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    this.imageUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'related_id': relatedId,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'image_url': imageUrl,
  };

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    relatedId: relatedId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    imageUrl: imageUrl,
  );
}

