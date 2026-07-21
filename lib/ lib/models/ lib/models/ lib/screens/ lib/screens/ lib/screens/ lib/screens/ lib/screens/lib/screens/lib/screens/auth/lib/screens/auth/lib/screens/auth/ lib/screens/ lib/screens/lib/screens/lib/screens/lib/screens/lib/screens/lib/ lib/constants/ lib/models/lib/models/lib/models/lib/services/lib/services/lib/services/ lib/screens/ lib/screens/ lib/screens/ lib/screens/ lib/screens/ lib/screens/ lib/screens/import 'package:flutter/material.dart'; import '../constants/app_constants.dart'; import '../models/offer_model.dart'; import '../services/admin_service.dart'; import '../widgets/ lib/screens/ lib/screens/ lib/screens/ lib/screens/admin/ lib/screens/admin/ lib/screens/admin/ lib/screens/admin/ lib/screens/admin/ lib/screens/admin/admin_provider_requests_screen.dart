import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/provider_request_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminProviderRequestsScreen extends StatefulWidget {
  const AdminProviderRequestsScreen({super.key});

  @override
  State<AdminProviderRequestsScreen> createState() => _AdminProviderRequestsScreenState();
}

class _AdminProviderRequestsScreenState extends State<AdminProviderRequestsScreen> {
  List<ProviderRequestModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getPendingRequests();
      setState(() => _requests = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    await AdminService.approveRequest(id);
    _load();
  }

  Future<void> _reject(String id) async {
    await AdminService.rejectRequest(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات مقدمي الخدمات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const EmptyState(message: 'لا توجد طلبات معلقة')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final r = _requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(r.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: r.description != null ? Text(r.description!) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: AppColors.secondary),
                              onPressed: () => _approve(r.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: AppColors.danger),
                              onPressed: () => _reject(r.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

