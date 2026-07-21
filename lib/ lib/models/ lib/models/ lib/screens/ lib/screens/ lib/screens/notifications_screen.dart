import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../widgets/shared_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _notificationSubscription;

  NotificationType? _selectedType;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToRealtimeNotifications();
    _markAllAsReadOnOpen();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل');

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (_selectedType != null) {
        query = query.eq('type', _selectedType!.name);
      }

      if (_showUnreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _notifications = response
            .map((json) => AppNotification.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الإشعارات';
        _isLoading = false;
      });
    }
  }

  void _subscribeToRealtimeNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (mounted) {
            setState(() {
              _notifications = data
                  .map((json) => AppNotification.fromJson(json))
                  .toList();
            });
          }
        });
  }

  Future<void> _markAllAsReadOnOpen() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('فشل تحديث حالة القراءة: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('فشل تحديث الإشعار: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم حذف الإشعار'),
            backgroundColor: AppColors.dark,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل حذف الإشعار'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ مسح الكل'),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('

