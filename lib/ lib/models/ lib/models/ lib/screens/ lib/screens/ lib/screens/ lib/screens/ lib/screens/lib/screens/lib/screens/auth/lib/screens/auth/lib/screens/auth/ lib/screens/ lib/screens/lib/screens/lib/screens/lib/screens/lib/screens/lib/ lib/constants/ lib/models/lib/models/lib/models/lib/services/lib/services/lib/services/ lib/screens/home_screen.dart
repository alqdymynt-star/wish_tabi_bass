import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/supabase_service.dart';
import 'create_order_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'offers_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const MyOrdersScreen(),
    const OffersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'العروض'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final isAdmin = SupabaseService.isAdmin;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ويش تبي بس؟',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('اطلب أي شيء ونوصله لك بأسرع وقت', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 32),
            _CategoryGrid(),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('طلب جديد', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AppConstants.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final cat = AppConstants.categories[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateOrderScreen(category: cat)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconFor(cat), color: AppColors.primary, size: 32),
                const SizedBox(height: 8),
                Text(cat, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String cat) {
    switch (cat) {
      case 'إلكترونيات': return Icons.devices;
      case 'أدوات منزلية': return Icons.chair;
      case 'طعام': return Icons.restaurant;
      case 'توصيل مشاوير': return Icons.local_shipping;
      case 'صيانة': return Icons.build;
      case 'خدمات شخصية': return Icons.person_search;
      default: return Icons.category;
    }
  }
}

