import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  final String messId;
  const DashboardScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryIndigo, size: 80),
            const SizedBox(height: 16),
            const Text('Welcome to your Workspace!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Mess ID: $messId', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
