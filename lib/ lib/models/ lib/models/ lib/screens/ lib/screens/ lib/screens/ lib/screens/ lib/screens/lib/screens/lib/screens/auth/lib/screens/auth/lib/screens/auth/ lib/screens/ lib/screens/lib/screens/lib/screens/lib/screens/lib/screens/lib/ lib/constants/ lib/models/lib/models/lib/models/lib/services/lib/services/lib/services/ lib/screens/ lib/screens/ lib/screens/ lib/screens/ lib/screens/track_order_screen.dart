import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';

class TrackOrderScreen extends StatelessWidget {
  final OrderModel order;
  const TrackOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = ['قيد المراجعة', 'جاري التوصيل', 'تم التوصيل'];
    final currentIndex = steps.indexOf(order.status);

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(order.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ...List.generate(steps.length, (index) {
              final isDone = index <= currentIndex;
              final isCurrent = index == currentIndex;
              return Row(
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDone ? AppColors.secondary : Colors.grey.shade300,
                        child: isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                      if (index < steps.length - 1)
                        Container(width: 2, height: 40, color: isDone ? AppColors.secondary : Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isDone ? AppColors.dark : AppColors.grey,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

