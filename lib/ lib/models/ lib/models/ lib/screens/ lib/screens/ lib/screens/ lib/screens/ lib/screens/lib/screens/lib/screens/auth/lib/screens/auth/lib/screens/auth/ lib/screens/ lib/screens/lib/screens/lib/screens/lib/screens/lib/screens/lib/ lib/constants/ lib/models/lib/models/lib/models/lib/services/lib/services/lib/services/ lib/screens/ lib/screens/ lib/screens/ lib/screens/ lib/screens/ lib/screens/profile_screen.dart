import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final meta = user?.userMetadata;

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(meta?['name'] ?? 'المستخدم', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primary),
              title: const Text('رقم الجوال'),
              subtitle: Text(meta?['phone'] ?? 'غير متوفر'),
            ),
            ListTile(
              leading: const Icon(Icons.badge, color: AppColors.primary),
              title: const Text('نوع الحساب'),
              subtitle: Text(meta?['role'] == 'admin' ? 'مدير' : 'زبون'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

