import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/shared_widgets.dart';
import 'review_screen.dart';
import 'report_issue_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  Future<void> _cancel(BuildContext context) async {
    try {
      await OrderService.updateStatus(order.id, 'ملغي');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (order.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(order.imageUrl!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            Text(order.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StatusBadge(status: order.status),
            const SizedBox(height: 16),
            _infoRow('التصنيف', order.category),
            _infoRow('السعر', '${order.price.toStringAsFixed(2)} ر.س'),
            _infoRow('تاريخ الطلب', order.createdAt.toString().substring(0, 16)),
            if (order.description != null) ...[
              const SizedBox(height: 16),
              const Text('الوصف:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(order.description!),
            ],
            const SizedBox(height: 32),
            if (order.status == 'قيد المراجعة')
              CustomButton(
                text: 'إلغاء الطلب',
                onPressed: () => _cancel(context),
                color: AppColors.danger,
              ),
            if (order.status == 'تم التوصيل') ...[
              CustomButton(
                text: 'تقييم الطلب',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReviewScreen(orderId: order.id)),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'الإبلاغ عن مشكلة',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReportIssueScreen(orderId: order.id)),
                ),
                color: AppColors.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

