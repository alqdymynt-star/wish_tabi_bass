class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isActive;
  final String? providerId;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isActive = true,
    this.providerId,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'],
        price: (json['price'] ?? 0).toDouble(),
        category: json['category'] ?? 'أخرى',
        imageUrl: json['image_url'],
        isActive: json['is_active'] ?? true,
        providerId: json['provider_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_active': isActive,
        'provider_id': providerId,
        'created_at': createdAt.toIso8601String(),
      };
}

