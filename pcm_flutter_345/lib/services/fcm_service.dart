import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      _logger.i('FCM Service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize FCM Service: $e');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      _logger.i('User granted provisional permission');
    } else {
      _logger.w('User declined or has not accepted permission');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'pcm_notifications',
      'PCM Notifications',
      description: 'Notifications for PCM app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      _logger.i('FCM Token: $_fcmToken');
      
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (_fcmToken != null) {
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
    }
  }

  // Configure message handlers
  void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _logger.i('FCM Token refreshed: $token');
      // TODO: Send updated token to backend
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationAction(data);
    }
  }

  // Handle notification tap when app is opened from background
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification opened app: ${message.messageId}');
    _handleNotificationAction(message.data);
  }

  // Handle notification actions
  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'booking_confirmed':
        // Navigate to booking details
        _logger.i('Navigate to booking $id');
        break;
      case 'wallet_deposit':
        // Navigate to wallet
        _logger.i('Navigate to wallet');
        break;
      case 'tournament_update':
        // Navigate to tournament details
        _logger.i('Navigate to tournament $id');
        break;
      case 'match_result':
        // Navigate to match details
        _logger.i('Navigate to match $id');
        break;
      default:
        _logger.i('Unknown notification type: $type');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'pcm_notifications',
      'PCM Notifications',
      channelDescription: 'Notifications for PCM app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Send token to backend
  Future<void> sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to backend
      _logger.i('Sending FCM token to backend: $token');
    } catch (e) {
      _logger.e('Failed to send token to backend: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification count
  Future<int> getNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_count') ?? 0;
  }

  // Update notification count
  Future<void> updateNotificationCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_count', count);
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  final logger = Logger();
  logger.i('Received background message: ${message.messageId}');
  
  // Handle background message processing here
  // Note: UI operations are not allowed in background handlers
}