import 'dart:async';
import 'package:flutter/material.dart';

// USING SAFE PACKAGE IMPORTS
import 'package:messiq/core/theme/app_theme.dart';
// FIXED: Changed to auth_gate.dart to match your actual file!
import 'package:messiq/features/auth/views/auth_gate.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          // FIXED: Changed to AuthGate() to match your actual file!
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryIndigo, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                    ],
                  ),
                  child: Image.asset('assets/app_logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'MessIQ',
                style: TextStyle(
                  fontSize: 42, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white, 
                  letterSpacing: 2
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Smart Living OS',
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.white70, 
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
