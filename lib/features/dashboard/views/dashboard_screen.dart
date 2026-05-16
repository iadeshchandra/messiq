import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_home_view.dart';
import '../../profile/views/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String messId;
  const DashboardScreen({super.key, required this.messId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Array of the screens we can navigate to
    final List<Widget> screens = [
      DashboardHomeView(messId: widget.messId),
      ProfileScreen(messId: widget.messId),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: AppTheme.primaryIndigo.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryIndigo), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryIndigo), label: 'Profile'),
        ],
      ),
    );
  }
}
