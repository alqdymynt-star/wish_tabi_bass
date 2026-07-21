import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_constants.dart';
import '../../services/admin_service.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_products_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await AdminService.getDashboardStats();
      setState(() => _stats = stats);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatCards(stats: _stats),
                    const SizedBox(height: 24),
                    _ChartWidget(),
                    const SizedBox(height: 24),
                    _QuickActions(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCards extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('الطلبات', stats['total_orders'] ?? 0, Icons.receipt, AppColors.primary),
      _StatItem('جديدة', stats['pending_orders'] ?? 0, Icons.pending, AppColors.warning),
      _StatItem('مقدمي خدمات', stats['total_providers'] ?? 0, Icons.people, AppColors.secondary),
      _StatItem('المستخدمين', stats['total_users'] ?? 0, Icons.group, AppColors.danger),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const Spacer(),
                Text(item.value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
                Text(item.label, style: const TextStyle(color: AppColors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _ChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الطلبات الأسبوعية', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    _makeBar(0, 5), _makeBar(1, 8), _makeBar(2, 12),
                    _makeBar(3, 7), _makeBar(4, 15), _makeBar(5, 10), _makeBar(6, 18),
                  ],
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                          return Text(days[v.toInt()], style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action('الطلبات', Icons.receipt_long, const AdminOrdersScreen()),
      _Action('المستخدمين', Icons.people, const AdminUsersScreen()),
      _Action('المنتجات', Icons.inventory, const AdminProductsScreen()),
      _Action('الشكاوى', Icons.report, const AdminReportsScreen()),
    ];
    return Column(
      children: actions.map((a) => ListTile(
        leading: Icon(a.icon, color: AppColors.primary),
        title: Text(a.label),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => a.screen)),
      )).toList(),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Widget screen;
  _Action(this.label, this.icon, this.screen);
}

