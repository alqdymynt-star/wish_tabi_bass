import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/supabase_service.dart';
import '../widgets/shared_widgets.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? category;
  const CreateOrderScreen({super.key, this.category});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'أخرى';
  File? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) _category = widget.category!;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      String? imageUrl;
      if (_image != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseService.client.storage.from('orders').upload(fileName, _image!);
        imageUrl = SupabaseService.client.storage.from('orders').getPublicUrl(fileName);
      }
      final order = OrderModel(
        id: '',
        userId: SupabaseService.currentUserId!,
        title: _titleCtrl.text,
        description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
        category: _category,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
      await OrderService.createOrder(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الطلب بنجاح!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(label: 'عنوان الطلب', controller: _titleCtrl),
            const SizedBox(height: 16),
            CustomTextField(label: 'الوصف (اختياري)', controller: _descCtrl, maxLines: 3),
            const SizedBox(height: 16),
            CustomTextField(label: 'السعر التقريبي', controller: _priceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'التصنيف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c, textAlign: TextAlign.right))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _image != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.camera_alt, color: AppColors.grey), SizedBox(height: 8), Text('إضافة صورة')],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'إرسال الطلب', onPressed: _submit, isLoading: _loading),
          ],
        ),
      ),
    );
  }
}

