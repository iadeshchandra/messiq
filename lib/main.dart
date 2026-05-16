import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/views/splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MessIQApp()));
}

class MessIQApp extends StatelessWidget {
  const MessIQApp({super.key});

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
