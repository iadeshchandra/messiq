import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // UX STRATEGY: All features listed, with Killer Features sorted at the absolute top.
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'The Ultimate Finance Engine',
      'subtitle': 'Never argue over money again. Auto-calculate daily meal rates, track shared expenses, and instantly see who owes what in real-time.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppTheme.primaryIndigo,
    },
    {
      'title': 'Smart Market & Meals',
      'subtitle': 'Sync grocery checklists offline, vote on weekend meals, and manage your entire mess from one beautiful dashboard.',
      'icon': Icons.shopping_cart_rounded,
      'color': Colors.teal,
    },
    {
      'title': 'Utility Bill Auto-Split',
      'subtitle': 'Input the monthly internet, electricity, and gas bills. The app automatically splits it among members and adds it to their monthly dues.',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.blueAccent,
    },
    {
      'title': 'Manager Analytics',
      'subtitle': 'Get detailed monthly reports, track payment history, and monitor your mess performance with clean, easy-to-read data charts.',
      'icon': Icons.insights_rounded,
      'color': Colors.deepPurple,
    },
    {
      'title': 'AI-Powered Assistant',
      'subtitle': 'Let AI predict your monthly grocery costs, generate smart bazaar lists, and chase down pending payments for you.',
      'icon': Icons.auto_awesome_rounded,
      'color': Colors.orange,
    },
    {
      'title': 'Faith & Safety Mode',
      'subtitle': 'Silent modes during prayer times, daily inspirations, and an ICE vault for emergency contacts and blood groups.',
      'icon': Icons.health_and_safety_rounded,
      'color': Colors.redAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MessIQ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Login', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  // THE FIX: SingleChildScrollView prevents the "Bottom Overflowed" error on smaller screens
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(color: _features[index]['color'].withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(_features[index]['icon'], size: 100, color: _features[index]['color']),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _features[index]['title'], 
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark), 
                              textAlign: TextAlign.center
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _features[index]['subtitle'], 
                              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5), 
                              textAlign: TextAlign.center
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.primaryIndigo : Colors.grey.shade300, 
                    borderRadius: BorderRadius.circular(4)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
