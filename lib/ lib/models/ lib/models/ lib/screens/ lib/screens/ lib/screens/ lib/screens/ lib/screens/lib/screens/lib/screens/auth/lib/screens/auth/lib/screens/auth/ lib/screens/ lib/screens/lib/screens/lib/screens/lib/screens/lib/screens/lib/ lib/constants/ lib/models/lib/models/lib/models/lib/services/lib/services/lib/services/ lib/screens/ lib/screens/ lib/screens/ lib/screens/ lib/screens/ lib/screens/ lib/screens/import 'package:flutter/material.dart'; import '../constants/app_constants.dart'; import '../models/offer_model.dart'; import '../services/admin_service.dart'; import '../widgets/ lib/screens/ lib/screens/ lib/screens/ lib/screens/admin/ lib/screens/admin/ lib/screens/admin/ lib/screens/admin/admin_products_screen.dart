import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getAllProducts();
      setState(() => _products = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(ProductModel p) async {
    await AdminService.toggleProductStatus(p.id, !p.isActive);
    _load();
  }

  Future<void> _delete(ProductModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف "${p.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.deleteProduct(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المنتجات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const EmptyState(message: 'لا توجد منتجات')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: p.imageUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl!, width: 50, height: 50, fit: BoxFit.cover))
                            : const Icon(Icons.image, size: 50),
                        title: Text(p.name),
                        subtitle: Text('${p.category} • ${p.price.toStringAsFixed(2)} ر.س'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: p.isActive,
                              onChanged: (_) => _toggle(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () => _delete(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

