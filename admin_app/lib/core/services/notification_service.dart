import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AdminNotificationService {
  static final AdminNotificationService instance = AdminNotificationService._();
  AdminNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Timer? _pollingTimer;
  bool _initialized = false;

  // Initialize native local notifications settings
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[AdminNotifications] Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for Android 13+ (POST_NOTIFICATIONS)
    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[AdminNotifications] Initialized local notifications plugin successfully.');

    // Start polling backend notifications
    startPolling();
  }

  // Show a native status bar notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'admin_app_notifications_channel',
      'Admin Alerts',
      channelDescription: 'Notifications for new note uploads pending review',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Periodic polling helper (runs every 30 seconds while app is active)
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await checkForNewNotifications();
    });
    debugPrint('[AdminNotifications] Started backend polling every 30 seconds.');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('[AdminNotifications] Polling stopped.');
  }

  // Check for any unread backend notifications and show native ones
  Future<void> checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        return; // Admin is logged out, skip check
      }

      // Fetch unread notifications from database using AdminApiService
      final response = await AdminApiService.request('GET', '/api/notifications');

      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> notifs = response.data['data'] ?? [];
        if (notifs.isEmpty) return;

        // Retrieve list of already notified notification IDs to avoid duplicates
        final List<String> notifiedIds = prefs.getStringList('notified_notification_ids') ?? [];
        final List<String> newNotifiedIds = List<String>.from(notifiedIds);

        bool hasNewNotification = false;

        for (var notif in notifs) {
          final String notifId = notif['_id']?.toString() ?? '';
          final bool isRead = notif['isRead'] ?? false;
          
          if (notifId.isNotEmpty && !isRead && !notifiedIds.contains(notifId)) {
            // Trigger native device notification!
            final String title = notif['title'] ?? '🔔 Admin Alert';
            final String message = notif['message'] ?? 'A new note is pending your approval.';
            
            // Map mongoose string ID hash code to unique integer ID
            final int integerId = notifId.hashCode;

            await showNotification(
              id: integerId,
              title: title,
              body: message,
              payload: notifId,
            );

            newNotifiedIds.add(notifId);
            hasNewNotification = true;
          }
        }

        if (hasNewNotification) {
          // Persist notified list
          await prefs.setStringList('notified_notification_ids', newNotifiedIds);
        }
      }
    } catch (e) {
      debugPrint('[AdminNotifications] Error polling notifications: $e');
    }
  }
}
