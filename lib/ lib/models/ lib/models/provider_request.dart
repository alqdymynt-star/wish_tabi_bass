enum ProviderRequestStatus {
  pending('قيد المراجعة', 0xFFFF9800),
  approved('تمت الموافقة', 0xFF4CAF50),
  rejected('مرفوض', 0xFFF44336);

  final String label;
  final int colorValue;
  const ProviderRequestStatus(this.label, this.colorValue);
}

class ProviderRequest {
  final String id;
  final String userId;
  final String businessName;
  final String category;
  final String description;
  final String phone;
  final String? email;
  final String? logoUrl;
  final List<String>? productImages;
  final double? priceRangeMin;
  final double? priceRangeMax;
  final ProviderRequestStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  ProviderRequest({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    required this.description,
    required this.phone,
    this.email,
    this.logoUrl,
    this.productImages,
    this.priceRangeMin,
    this.priceRangeMax,
    this.status = ProviderRequestStatus.pending,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ProviderRequest.fromJson(Map<String, dynamic> json) {
    return ProviderRequest(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      category: json['category'],
      description: json['description'],
      phone: json['phone'],
      email: json['email'],
      logoUrl: json['logo_url'],
      productImages: json['product_images'] != null
          ? List<String>.from(json['product_images'])
          : null,
      priceRangeMin: json['price_range_min']?.toDouble(),
      priceRangeMax: json['price_range_max']?.toDouble(),
      status: ProviderRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProviderRequestStatus.pending,
      ),
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'business_name': businessName,
    'category': category,
    'description': description,
    'phone': phone,
    'email': email,
    'logo_url': logoUrl,
    'product_images': productImages,
    'price_range_min': priceRangeMin,
    'price_range_max': priceRangeMax,
    'status': status.name,
    'admin_note': adminNote,
    'created_at': createdAt.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
  };
}

