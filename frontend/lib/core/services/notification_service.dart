import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/api_config.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Timer? _pollingTimer;
  final Dio _dio = Dio();
  bool _initialized = false;

  // Initialize native local notifications settings
  Future<void> initialize() async {
    if (_initialized) return;

    // Web platform does not support native local notifications via this plugin
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
        // Handle tapping notification in device status bar if desired
        debugPrint('[Notifications] Notification tapped: ${response.payload}');
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
    debugPrint('[Notifications] Initialized local notifications plugin successfully.');

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
      'notes_marketplace_notifications_channel',
      'Marketplace Updates',
      channelDescription: 'Notifications for notes approval and buy orders',
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
    debugPrint('[Notifications] Started backend polling every 30 seconds.');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('[Notifications] Polling stopped.');
  }

  // Check for any unread backend notifications and show native ones
  Future<void> checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        return; // User is logged out, skip check
      }

      // Fetch unread notifications from database
      final response = await _dio.get(
        '$backendBaseUrl/notifications',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
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
            final String title = notif['title'] ?? '🔔 CloudNotes Alert';
            final String message = notif['message'] ?? 'You have a new update in your study dashboard.';
            
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
      debugPrint('[Notifications] Error polling notifications: $e');
    }
  }
}
