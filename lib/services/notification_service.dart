// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../models/shop_item.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel IDs
  static const String _channelId = 'shopping_reminder_channel';
  static const String _channelName = 'Shopping Reminders';
  static const String _channelDesc = 'Notifications for nearby shopping reminders';

  /// Check if notifications are initialized
  bool get isInitialized => _initialized;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Initialize settings for both platforms
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize notifications plugin
      final initialized = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized ?? false) {
        // Create notification channel for Android
        await _createNotificationChannel();
        _initialized = true;
        return true;
      }

      return false;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  /// Create the notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Implement navigation to specific item or shopping list
    print('Notification tapped: ${response.payload}');
  }

  /// Check if notification permissions are granted
  Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      } else {
        // For iOS, check if notifications can be scheduled
        final enabled = await _notifications
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return enabled ?? false;
      }
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      } else {
        // For iOS
        final iosPermission = await _notifications
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return iosPermission ?? false;
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show a nearby shop notification
  Future<void> showNearbyShopNotification(ShopItem item) async {
    if (!_initialized) return;

    try {
      // Android specific notification details
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Shopping Reminder',
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'You have items to buy at ${item.shopName}',
          contentTitle: 'Nearby Shopping Reminder',
          summaryText: item.itemName,
        ),
      );

      // iOS specific notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for both platforms
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        item.id.hashCode, // Use item ID hash as notification ID
        'Nearby Shopping Reminder',
        'Don\'t forget to buy ${item.itemName} at ${item.shopName}',
        details,
        payload: item.id, // Store item ID as payload for tap handling
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Show a batch notification for multiple nearby items
  Future<void> showBatchNearbyNotification(List<ShopItem> items) async {
    if (!_initialized || items.isEmpty) return;

    try {
      final itemCount = items.length;
      final shopCount = items.map((item) => item.shopName).toSet().length;

      // Create summary text
      final String title = 'Shopping Reminders Nearby';
      final String body = 'You have $itemCount ${itemCount == 1 ? 'item' : 'items'} '
          'to buy at $shopCount ${shopCount == 1 ? 'shop' : 'shops'} nearby';

      // Android specific notification details with inbox style
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: InboxStyleInformation(
          items.map((item) => '${item.itemName} at ${item.shopName}').toList(),
          contentTitle: title,
          summaryText: '$itemCount items nearby',
        ),
      );

      // iOS specific notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the batch notification
      await _notifications.show(
        'batch'.hashCode,
        title,
        body,
        details,
        payload: 'batch_notification',
      );
    } catch (e) {
      print('Error showing batch notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String itemId) async {
    if (!_initialized) return;
    await _notifications.cancel(itemId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
  }
}