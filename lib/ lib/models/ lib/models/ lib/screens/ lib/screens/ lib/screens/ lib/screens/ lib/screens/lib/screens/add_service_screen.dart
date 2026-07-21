import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_request.dart';
import '../widgets/shared_widgets.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  String? _selectedCategory;
  File? _logoImage;
  final List<File> _productImages = [];
  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _agreedToTerms = false;

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
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _logoImage = File(picked.path));
    }
  }

  Future<void> _addProductImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        for (var image in picked) {
          if (_productImages.length < 5) {
            _productImages.add(File(image.path));
          }
        }
      });
    }
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = '$folder/$fileName';
      await _supabase.storage.from('provider_requests').upload(path, file);
      return _supabase.storage.from('provider_requests').getPublicUrl(path);
    } catch (e) {
      debugPrint('فشل رفع الملف: $e');
      return null;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('يرجى اختيار تصنيف الخدمة');
      return;
    }
    if (!_agreedToTerms) {
      _showError('يرجى الموافقة على الشروط والأحكام');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل');

      String? logoUrl;
      if (_logoImage != null) {
        logoUrl = await _uploadFile(_logoImage!, 'logos');
      }

      List<String>? productImageUrls;
      if (_productImages.isNotEmpty) {
        productImageUrls = [];
        for (var image in _productImages) {
          final url = await _uploadFile(image, 'products');
          if (url != null) productImageUrls.add(url);
        }
      }

      final request = ProviderRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        logoUrl: logoUrl,
        productImages: productImageUrls?.isEmpty ?? true ? null : productImageUrls,
        priceRangeMin: _priceMinController.text.isNotEmpty
            ? double.parse(_priceMinController.text)
            : null,
        priceRangeMax: _priceMaxController.text.isNotEmpty
            ? double.parse(_priceMaxController.text)
            : null,
        createdAt: DateTime.now(),
      );

      await _supabase.from('provider_requests').insert(request.toJson());

      await _supabase.from('notifications').insert({
        'user_id': 'admin',
        'title': '🏪 طلب انضمام جديد',
        'body': 'طلب جديد من ${_businessNameController.text} للانضمام كمقدم خدمة',
        'type': 'system',
        'related_id': request.id,
      });

      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('فشل إرسال الطلب: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'انضم كمقدم خدمة',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8B5CF6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ابدأ رحلتك كمقدم خدمة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'املأ النموذج أدناه وسيقوم فريقنا بمراجعة طلبك خلال 1-3 أيام عمل.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('شعار النشاط التجاري'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLogo,
              child: _logoImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _logoImage!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.sashed,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'إضافة شعار',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('اسم النشاط التجاري *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _businessNameController,
              decoration: _inputDecoration(
                hintText: 'مثال: متجر الأناقة',
                icon: Icons.store,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم النشاط';
                }
                if (value.trim().length < 3) {
                  return 'الاسم قصير جداً';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('تصنيف الخدمة *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.dark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('وصف الخدمة *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                hintText: 'اشرح خدماتك بالتفصيل...',
                icon: Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى كتابة وصف الخدمة';
                }
                if (value.trim().length < 20) {
                  return 'الوصف قصير جداً (20 حرف على الأقل)';
                }
                return null;
              },
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('معلومات التواصل'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration(
                hintText: 'رقم الجوال',
                icon: Icons.phone,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الجوال';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(
                hintText: 'البريد الإلكتروني (اختياري)',
                icon: Icons.email_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('نطاق السعر المتوقع (ر.س)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceMinController,
                    decoration: _inputDecoration(
                      hintText: 'من',
                      icon: Icons.arrow_downward,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('—', style: TextStyle(fontSize: 20, color: AppColors.grey)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _priceMaxController,
                    decoration: _inputDecoration(
                      hintText: 'إلى',
                      icon: Icons.arrow_upward,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('صور المنتجات أو الخدمات'),
            const SizedBox(height: 8),
            Text(
              'أضف حتى 5 صور لمنتجاتك أو أعمالك السابقة',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _addProductImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.sashed,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 28,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إضافة',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._productImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            image: DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _productImages.removeAt(entry.key));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Text.rich(
                        TextSpan(
                          text: 'أوافق على ',
                          style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.5),
                          children: const [
                            TextSpan(
                              text: 'شروط وأحكام',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(
                              text: ' تقديم الخدمات عبر المنصة، وأتعهد بصحة المعلومات المقدمة.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'إرسال الطلب للمراجعة',
              onPressed: _isSubmitting ? null : _submitRequest,
              isLoading: _isSubmitting,
              icon: Icons.send,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيتم مراجعة طلبك من قبل الإدارة. ستصلك إشعار عند الموافقة أو الرفض.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppColors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تم إرسال طلبك بنجاح!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'فريقنا سيقوم بمراجعة معلوماتك خلال 1-3 أيام عمل. ستصلك إشعار فوراً عند اتخاذ القرار.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'وقت المراجعة المتوقع: 1-3 أيام',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'العودة للرئيسية',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

