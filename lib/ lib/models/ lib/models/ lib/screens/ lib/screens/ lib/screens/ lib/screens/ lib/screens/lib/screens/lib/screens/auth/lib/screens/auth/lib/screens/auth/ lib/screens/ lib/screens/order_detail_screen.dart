import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/shared_widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (order.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          order.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image, color: AppColors.primary),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(
                            text: order.status.label,
                            color: Color(order.status.colorValue),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (order.price != null)
                            Text(
                              '${order.price!.toStringAsFixed(0)} ر.س',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                InfoRow(
                  icon: Icons.folder_open,
                  label: 'التصنيف',
                  value: order.category,
                ),
                const SizedBox(height: 12),
                InfoRow(
                  icon: Icons.description,
                  label: 'الوصف',
                  value: order.description,
                ),
                const SizedBox(height: 12),
                if (order.customerAddress != null)
                  InfoRow(
                    icon: Icons.location_on,
                    label: 'عنوان التوصيل',
                    value: order.customerAddress!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (order.status == OrderStatus.delivered && order.rating == null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قيّم الخدمة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.star_border,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

