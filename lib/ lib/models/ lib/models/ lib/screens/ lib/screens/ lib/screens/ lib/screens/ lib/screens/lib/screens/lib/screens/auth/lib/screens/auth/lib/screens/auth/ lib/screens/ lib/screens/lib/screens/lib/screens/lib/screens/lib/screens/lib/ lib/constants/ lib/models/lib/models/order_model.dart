class OrderModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final double price;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? providerId;

  OrderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.price,
    this.status = 'قيد المراجعة',
    this.imageUrl,
    required this.createdAt,
    this.deliveredAt,
    this.providerId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'] ?? '',
        description: json['description'],
        category: json['category'] ?? 'أخرى',
        price: (json['price'] ?? 0).toDouble(),
        status: json['status'] ?? 'قيد المراجعة',
        imageUrl: json['image_url'],
        createdAt: DateTime.parse(json['created_at']),
        deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
        providerId: json['provider_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'status': status,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'provider_id': providerId,
      };
}

