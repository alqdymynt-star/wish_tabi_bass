import 'package:google_maps_flutter/google_maps_flutter.dart';

enum OrderStatus {
  pending('قيد المراجعة', 0xFFFF9800),
  accepted('تم القبول', 0xFF2196F3),
  preparing('جاري التحضير', 0xFF9C27B0),
  onTheWay('جاري التوصيل', 0xFF03A9F4),
  delivered('تم التوصيل', 0xFF4CAF50),
  cancelled('ملغي', 0xFFF44336);

  final String label;
  final int colorValue;
  const OrderStatus(this.label, this.colorValue);
}

class Order {
  final String id;
  final String userId;
  final String? providerId;
  final String title;
  final String description;
  final String category;
  final double? price;
  final String? imageUrl;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final LatLng? customerLocation;
  final LatLng? providerLocation;
  final String? customerAddress;
  final String? providerName;
  final String? providerPhone;
  final String? providerImage;
  final double? rating;
  final String? review;

  Order({
    required this.id,
    required this.userId,
    this.providerId,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    this.imageUrl,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.deliveredAt,
    this.customerLocation,
    this.providerLocation,
    this.customerAddress,
    this.providerName,
    this.providerPhone,
    this.providerImage,
    this.rating,
    this.review,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      providerId: json['provider_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      price: json['price']?.toDouble(),
      imageUrl: json['image_url'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      customerLocation: json['customer_lat'] != null && json['customer_lng'] != null
          ? LatLng(json['customer_lat'], json['customer_lng'])
          : null,
      providerLocation: json['provider_lat'] != null && json['provider_lng'] != null
          ? LatLng(json['provider_lat'], json['provider_lng'])
          : null,
      customerAddress: json['customer_address'],
      providerName: json['provider_name'],
      providerPhone: json['provider_phone'],
      providerImage: json['provider_image'],
      rating: json['rating']?.toDouble(),
      review: json['review'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'provider_id': providerId,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'image_url': imageUrl,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'customer_lat': customerLocation?.latitude,
    'customer_lng': customerLocation?.longitude,
    'provider_lat': providerLocation?.latitude,
    'provider_lng': providerLocation?.longitude,
    'customer_address': customerAddress,
    'provider_name': providerName,
    'provider_phone': providerPhone,
    'provider_image': providerImage,
    'rating': rating,
    'review': review,
  };
}

