import 'package:flutter/material.dart';
import 'package:messiq/core/theme/app_theme.dart';
import 'package:messiq/features/auth/views/auth_gate.dart'; // Make sure this is imported

class MessIqApp extends StatelessWidget {
  const MessIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessIQ',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // This replaces the "Initialized" text
    );
  }
}
