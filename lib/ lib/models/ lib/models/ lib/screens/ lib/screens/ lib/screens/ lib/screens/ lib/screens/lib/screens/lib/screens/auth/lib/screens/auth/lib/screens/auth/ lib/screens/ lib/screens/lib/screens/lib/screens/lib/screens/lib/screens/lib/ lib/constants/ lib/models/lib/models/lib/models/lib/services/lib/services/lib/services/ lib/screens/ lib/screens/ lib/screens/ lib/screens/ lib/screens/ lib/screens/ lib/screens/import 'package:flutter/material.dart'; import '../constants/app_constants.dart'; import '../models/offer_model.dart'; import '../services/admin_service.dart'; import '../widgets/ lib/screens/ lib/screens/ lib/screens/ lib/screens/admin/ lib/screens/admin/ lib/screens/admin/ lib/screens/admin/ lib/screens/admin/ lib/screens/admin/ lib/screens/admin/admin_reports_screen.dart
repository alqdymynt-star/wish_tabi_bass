import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/report_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<ReportModel> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getAllReports();
      setState(() => _reports = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String id) async {
    await AdminService.resolveReport(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإبلاغات والشكاوى')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const EmptyState(message: 'لا توجد إبلاغات')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final r = _reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(r.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.details != null) Text(r.details!),
                            const SizedBox(height: 4),
                            StatusBadge(status: r.status),
                          ],
                        ),
                        trailing: r.status != 'محلول'
                            ? IconButton(
                                icon: const Icon(Icons.check, color: AppColors.secondary),
                                onPressed: () => _resolve(r.id),
                              )
                            : const Icon(Icons.check_circle, color: AppColors.secondary),
                      ),
                    );
                  },
                ),
    );
  }
}

