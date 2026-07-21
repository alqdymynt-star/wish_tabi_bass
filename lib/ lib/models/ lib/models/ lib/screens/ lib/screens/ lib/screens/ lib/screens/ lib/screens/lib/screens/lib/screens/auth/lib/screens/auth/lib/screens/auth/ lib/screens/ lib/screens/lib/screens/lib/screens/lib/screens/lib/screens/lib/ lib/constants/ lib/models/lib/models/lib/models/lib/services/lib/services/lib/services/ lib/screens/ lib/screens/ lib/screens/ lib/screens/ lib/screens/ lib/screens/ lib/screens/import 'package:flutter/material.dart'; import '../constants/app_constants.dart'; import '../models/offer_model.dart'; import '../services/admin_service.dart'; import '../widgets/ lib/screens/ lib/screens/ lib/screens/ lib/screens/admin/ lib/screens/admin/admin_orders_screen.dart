import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getAllOrders();
      setState(() => _orders = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<OrderModel> get _filtered {
    if (_filter == 'الكل') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  Future<void> _changeStatus(OrderModel order, String status) async {
    try {
      await AdminService.updateOrderStatus(order.id, status);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبات')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['الكل', ...AppConstants.orderStatuses].map((s) {
                final selected = _filter == s;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = s),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.dark),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(message: 'لا توجد طلبات')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final o = _filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ExpansionTile(
                              title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${o.category} • ${o.price.toStringAsFixed(2)} ر.س'),
                              trailing: StatusBadge(status: o.status),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Wrap(
                                    spacing: 8,
                                    children: AppConstants.orderStatuses.map((s) {
                                      return ActionChip(
                                        label: Text('تعيين: $s'),
                                        onPressed: () => _changeStatus(o, s),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

