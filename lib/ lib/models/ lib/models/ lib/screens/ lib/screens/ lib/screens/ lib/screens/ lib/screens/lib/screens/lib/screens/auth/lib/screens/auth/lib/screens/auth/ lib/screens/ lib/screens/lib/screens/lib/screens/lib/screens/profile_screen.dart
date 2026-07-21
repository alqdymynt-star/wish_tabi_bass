import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _profile = response;
        _nameController.text = response['full_name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث الملف الشخصي'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل التحديث'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
      //   builder: (_) => const LoginScreen(),
      // ), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: _profile?['avatar_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(_profile!['avatar_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profile?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          hintText: 'الاسم الكامل',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hintText: 'رقم الجوال',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _profile?['email'] ?? '',
                        enabled: false,
                        decoration: _inputDecoration(
                          hintText: 'البريد الإلكتروني',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _profile?['role'] == 'admin' ? 'مدير' : 'عميل',
                        enabled: false,
                        decoration: _inputDecoration(
                          hintText: 'نوع الحساب',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'حفظ التغييرات',
                  onPressed: _updateProfile,
                  icon: Icons.save,
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  text: 'تغيير كلمة المرور',
                  icon: Icons.lock_outline,
                  onPressed: () {},
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: Colors.white,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

