import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/offer_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  List<OfferModel> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getAllOffers();
      setState(() => _offers = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOffer() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('عرض جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف')),
            TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'نسبة الخصم %'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (result == true) {
      final offer = OfferModel(
        id: '',
        title: titleCtrl.text,
        description: descCtrl.text.isEmpty ? null : descCtrl.text,
        discountPercent: double.tryParse(discountCtrl.text) ?? 0,
        createdAt: DateTime.now(),
      );
      await AdminService.createOffer(offer);
      _load();
    }
  }

  Future<void> _delete(String id) async {
    await AdminService.deleteOffer(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العروض')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOffer,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? const EmptyState(message: 'لا توجد عروض')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final o = _offers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(o.title),
                        subtitle: Text('خصم ${o.discountPercent}%'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.danger),
                          onPressed: () => _delete(o.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

