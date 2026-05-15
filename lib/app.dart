import 'package:flutter/material.dart';
import 'package:messiq/core/theme/app_theme.dart';
import 'package:messiq/features/auth/views/auth_gate.dart';

class MessIqApp extends StatelessWidget {
  const MessIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessIQ',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // This routes the app to the Phase 2 Auth System
      home: const AuthGate(), 
    );
  }
}
