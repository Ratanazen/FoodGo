import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/config/firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;
  static String? _fcmToken;

  static bool get isInitialized => _initialized;
  static String? get fcmToken => _fcmToken;

  /// Initializes Firebase and Cloud Messaging safely.
  /// Handles platform limitations, offline states, and placeholder keys gracefully.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        debugPrint('Firebase is not natively supported on Linux desktop.');
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully for project foodgo-59da7');

      // Setup Cloud Messaging if on supported platform
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await _setupFCM();
      }
    } catch (e) {
      debugPrint(
        'Firebase initialization notice: $e (running in offline/mock mode)',
      );
    }
  }

  static Future<void> _setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'FCM Notification permission status: ${settings.authorizationStatus}',
      );

      // Retrieve device token
      // ignore: deprecated_member_use
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('Firebase FCM Device Token: $_fcmToken');
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'Foreground FCM notification: ${message.notification?.title} - ${message.notification?.body}',
        );
      });
    } catch (e) {
      debugPrint('Firebase Cloud Messaging setup notice: $e');
    }
  }
}
