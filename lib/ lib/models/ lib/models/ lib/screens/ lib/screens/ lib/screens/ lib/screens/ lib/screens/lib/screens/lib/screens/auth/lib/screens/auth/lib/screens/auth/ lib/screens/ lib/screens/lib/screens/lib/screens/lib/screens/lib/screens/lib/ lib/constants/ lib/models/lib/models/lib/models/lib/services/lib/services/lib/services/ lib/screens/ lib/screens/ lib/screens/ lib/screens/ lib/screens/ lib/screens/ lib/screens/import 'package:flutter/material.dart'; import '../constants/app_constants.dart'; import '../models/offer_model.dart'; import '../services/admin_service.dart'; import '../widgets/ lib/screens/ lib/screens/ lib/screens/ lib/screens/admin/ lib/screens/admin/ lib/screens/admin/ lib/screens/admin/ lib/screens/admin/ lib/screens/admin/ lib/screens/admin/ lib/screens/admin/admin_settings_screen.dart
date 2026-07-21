import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  double _commission = 10;
  bool _cashOnDelivery = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('نسبة العمولة %'),
              subtitle: Slider(
                value: _commission,
                min: 0,
                max: 50,
                divisions: 50,
                label: _commission.round().toString(),
                onChanged: (v) => setState(() => _commission = v),
              ),
              trailing: Text('${_commission.round()}%'),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('الدفع عند الاستلام'),
              subtitle: const Text('تفعيل خيار الدفع النقدي'),
              value: _cashOnDelivery,
              onChanged: (v) => setState(() => _cashOnDelivery = v),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الإعدادات')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

