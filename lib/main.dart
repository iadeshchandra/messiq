import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/views/splash_screen.dart'; 
import 'firebase_options.dart'; 
import 'core/services/notification_service.dart'; 

// 🚨 REQUIRED: This function must be outside of any class to run in the background!
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );

  // Register the background listener
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const ProviderScope(child: MessIQApp()));
}

// Converted to Stateful Widget so we can initialize notifications on boot
class MessIQApp extends StatefulWidget {
  const MessIQApp({super.key});

  @override
  State<MessIQApp> createState() => _MessIQAppState();
}

class _MessIQAppState extends State<MessIQApp> {
  
  @override
  void initState() {
    super.initState();
    // Wake up the Notification Service the second the app launches!
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryIndigo,
        scaffoldBackgroundColor: AppTheme.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textDark),
          titleTextStyle: TextStyle(
            color: AppTheme.textDark, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}
