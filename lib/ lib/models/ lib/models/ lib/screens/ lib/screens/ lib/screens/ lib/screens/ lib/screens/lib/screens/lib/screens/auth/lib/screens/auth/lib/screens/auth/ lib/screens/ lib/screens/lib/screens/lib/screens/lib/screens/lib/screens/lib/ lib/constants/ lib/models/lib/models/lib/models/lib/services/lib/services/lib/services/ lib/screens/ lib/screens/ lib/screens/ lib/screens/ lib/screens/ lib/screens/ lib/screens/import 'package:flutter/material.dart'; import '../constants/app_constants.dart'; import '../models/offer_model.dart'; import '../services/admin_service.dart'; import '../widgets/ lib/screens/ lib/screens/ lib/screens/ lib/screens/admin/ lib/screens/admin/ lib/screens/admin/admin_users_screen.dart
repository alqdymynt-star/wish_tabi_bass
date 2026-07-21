import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminService.getAllUsers();
      setState(() => _users = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(UserModel user) async {
    await AdminService.toggleUserStatus(user.id, !user.isActive);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const EmptyState(message: 'لا يوجد مستخدمين')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(u.name[0]),
                        ),
                        title: Text(u.name),
                        subtitle: Text('${u.email} • ${u.phone}'),
                        trailing: Switch(
                          value: u.isActive,
                          onChanged: (_) => _toggle(u),
                          activeColor: AppColors.secondary,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

