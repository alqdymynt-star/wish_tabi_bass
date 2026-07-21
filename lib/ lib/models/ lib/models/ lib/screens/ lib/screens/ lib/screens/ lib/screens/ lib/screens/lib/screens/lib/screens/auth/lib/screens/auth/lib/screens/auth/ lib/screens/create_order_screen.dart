import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../widgets/shared_widgets.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedCategory;
  File? _orderImage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'إلكترونيات',
    'أدوات منزلية',
    'طعام ومشروبات',
    'توصيل مشاوير',
    'صيانة',
    'خدمات شخصية',
    'تعليم',
    'صحة وجمال',
    'أخرى',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _orderImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_orderImage == null) return null;
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_orderImage!.path.split('/').last}';
      final path = 'orders/$fileName';
      await Supabase.instance.client.storage.from('orders').upload(path, _orderImage!);
      return Supabase.instance.client.storage.from('orders').getPublicUrl(path);
    } catch (e) {
      debugPrint('فشل رفع الصورة: $e');
      return null;
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('يرجى اختيار التصنيف');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل');

      final imageUrl = await _uploadImage();

      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        customerAddress: _addressController.text.trim(),
      );

      await Supabase.instance.client.from('orders').insert(order.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الطلب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('فشل إرسال الطلب: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('طلب جديد'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ويش تبي بس؟',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اكتب لنا أي شيء تبيه ونوصله لك!',
              style: TextStyle(fontSize: 14, color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: _orderImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _orderImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.sashed),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: AppColors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text('إضافة صورة للطلب (اختياري)', style: TextStyle(color: AppColors.grey.withOpacity(0.7))),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(hintText: 'عنوان الطلب (مثال: آيفون 15 برو)', icon: Icons.shopping_bag_outlined),
              validator: (value) => value == null || value.trim().isEmpty ? 'يرجى إدخال عنوان الطلب' : null,
            ),
            const SizedBox(height: 16),
            const Text('التصنيف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.dark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(hintText: 'وصف تفصيلي للطلب...', icon: Icons.description_outlined),
              maxLines: 4,
              maxLength: 500,
              validator: (value) => value == null || value.trim().length < 10 ? 'الوصف قصير جداً' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hintText: 'السعر المتوقع (ر.س) - اختياري', icon: Icons.attach_money),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(hintText: 'عنوان التوصيل', icon: Icons.location_on_outlined),
              validator: (value) => value == null || value.trim().isEmpty ? 'يرجى إدخال العنوان' : null,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'إرسال الطلب',
              onPressed: _isSubmitting ? null : _submitOrder,
              isLoading: _isSubmitting,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

