import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request permission (Required for iOS and newer Android versions)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the unique device token
      String? token = await _messaging.getToken();
      if (token != null) {
        _saveTokenToDatabase(token);
      }

      // 3. Listen for token refreshes (in case the device cycles its ID)
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    }
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save the token to the user's profile so the MessIQ server can find them
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }
}
