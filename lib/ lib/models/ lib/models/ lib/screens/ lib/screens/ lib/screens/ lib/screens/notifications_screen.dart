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
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      setState(() => _notifications.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل مسح الإشعارات'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    _markAsRead(notification.id);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'الإشعارات',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount جديد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('مسح الكل'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeFilterChip(
                    label: 'الكل',
                    isSelected: _selectedType == null && !_showUnreadOnly,
                    onTap: () {
                      setState(() {
                        _selectedType = null;
                        _showUnreadOnly = false;
                      });
                      _loadNotifications();
                    },
                  ),
                  const SizedBox(width: 8),
                  _TypeFilterChip(
                    label: 'غير مقروء',
                    isSelected: _showUnreadOnly,
                    icon: Icons.mark_email_unread,
                    badgeCount: unreadCount,
                    onTap: () {
                      setState(() {
                        _showUnreadOnly = !_showUnreadOnly;
                        _selectedType = null;
                      });
                      _loadNotifications();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...NotificationType.values.map((type) {
                    final count = _notifications
                        .where((n) => n.type == type && !n.isRead)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _TypeFilterChip(
                        label: type.label,
                        isSelected: _selectedType == type,
                        badgeCount: count > 0 ? count : null,
                        onTap: () {
                          setState(() {
                            _selectedType = _selectedType == type ? null : type;
                            _showUnreadOnly = false;
                          });
                          _loadNotifications();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const SkeletonList()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _loadNotifications)
                    : _notifications.isEmpty
                        ? EmptyState(
                            title: 'لا توجد إشعارات',
                            subtitle: _showUnreadOnly
                                ? 'جميع الإشعارات مقروءة ✅'
                                : 'ستظهر هنا إشعارات طلباتك ورسائلك',
                            icon: Icons.notifications_off_outlined,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return Dismissible(
                                  key: Key(notification.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  onDismissed: (_) => _deleteNotification(notification.id),
                                  child: FadeSlideTransition(
                                    index: index,
                                    child: _NotificationCard(
                                      notification: notification,
                                      onTap: () => _handleNotificationTap(notification),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GlassCard(
      onTap: onTap,
      backgroundColor: isUnread ? Colors.white : Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getTypeIcon(),
              color: _getTypeColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.grey.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.orderUpdate:
        return AppColors.primary;
      case NotificationType.newMessage:
        return AppColors.secondary;
      case NotificationType.promotion:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.reviewRequest:
        return AppColors.accent;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.reviewRequest:
        return Icons.star_border;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final int? badgeCount;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.isSelected,
    this.icon,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.light,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.grey,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.grey,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

