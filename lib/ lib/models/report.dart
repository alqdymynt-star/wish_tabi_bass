enum ReportReason {
  delay('تأخير في التوصيل'),
  wrongOrder('طلب خاطئ'),
  badService('خدمة سيئة'),
  damagedItem('منتج تالف'),
  rudeBehavior('سلوك غير لائق'),
  other('سبب آخر');

  final String label;
  const ReportReason(this.label);
}

enum ReportStatus {
  pending('قيد المراجعة', 0xFFFF9800),
  resolved('تم الحل', 0xFF4CAF50),
  rejected('مرفوض', 0xFFF44336);

  final String label;
  final int colorValue;
  const ReportStatus(this.label, this.colorValue);
}

class Report {
  final String id;
  final String orderId;
  final String userId;
  final ReportReason reason;
  final String? customReason;
  final String description;
  final String? imageUrl;
  final ReportStatus status;
  final DateTime createdAt;
  final String? adminResponse;

  Report({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.reason,
    this.customReason,
    required this.description,
    this.imageUrl,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.adminResponse,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      customReason: json['custom_reason'],
      description: json['description'],
      imageUrl: json['image_url'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      adminResponse: json['admin_response'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'user_id': userId,
    'reason': reason.name,
    'custom_reason': customReason,
    'description': description,
    'image_url': imageUrl,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'admin_response': adminResponse,
  };
}

