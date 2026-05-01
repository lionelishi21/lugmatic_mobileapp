import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/core/navigation/app_navigator_key.dart';
import 'notification_service.dart';

class FcmService {
  final NotificationService _notificationService;

  FcmService({required NotificationService notificationService})
      : _notificationService = notificationService;

  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background FCM message: ${message.messageId}');
  }

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Foreground messages — show an in-app SnackBar banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _showInAppBanner(
        title: notification.title ?? 'Lugmatic',
        body: notification.body ?? '',
        data: message.data,
      );
    });

    // Notification tap when app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Notification tap that cold-started the app
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _notificationService.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  void _showInAppBanner({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: const Color(0xFF10B981),
          onPressed: () => _handleNotificationTap(data),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;
    final targetId = data['targetId'] as String? ?? data['contentId'] as String?;

    switch (type) {
      case 'live_stream':
        if (targetId != null) {
          navigator.pushNamed('/live', arguments: targetId);
        } else {
          navigator.pushNamed('/home');
        }
        break;
      case 'clash_invitation':
        if (targetId != null) {
          navigator.pushNamed('/clash', arguments: targetId);
        }
        break;
      case 'gift_received':
      case 'new_release':
      default:
        navigator.pushNamed('/home');
    }
  }
}
