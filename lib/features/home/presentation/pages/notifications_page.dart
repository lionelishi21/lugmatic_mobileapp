import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lugmatic_flutter/data/models/notification_model.dart';
import 'package:lugmatic_flutter/data/services/notification_service.dart';
import 'package:lugmatic_flutter/core/theme/neumorphic_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotificationService>();
      final items = await service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<NotificationService>().markAllAsRead();
      _fetchNotifications();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await context.read<NotificationService>().deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => n.id == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: NeumorphicTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: NeumorphicTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all as read', style: TextStyle(color: NeumorphicTheme.primaryAccent, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: NeumorphicTheme.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll let you know when something\nimportant happens.",
            style: TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.flatNeumorphicDecoration(
        color: notification.isRead ? NeumorphicTheme.backgroundColor : NeumorphicTheme.surfaceColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(notification.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: NeumorphicTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(notification.createdAt),
                      style: const TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: const TextStyle(color: NeumorphicTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: NeumorphicTheme.primaryAccent, shape: BoxShape.circle),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: NeumorphicTheme.textTertiary),
            onPressed: () => _deleteNotification(notification.id),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'comment':
        iconData = Icons.message_outlined;
        color = Colors.blue;
        break;
      case 'like':
        iconData = Icons.favorite_outline;
        color = Colors.red;
        break;
      case 'follow':
        iconData = Icons.person_add_outlined;
        color = Colors.green;
        break;
      case 'gift':
        iconData = Icons.card_giftcard;
        color = NeumorphicTheme.primaryAccent;
        break;
      default:
        iconData = Icons.notifications_none;
        color = NeumorphicTheme.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
