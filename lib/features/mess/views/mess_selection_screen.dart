import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import 'create_mess_screen.dart';
import 'join_mess_screen.dart';

class MessSelectionScreen extends ConsumerWidget {
  const MessSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MessIQ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  )
                ],
              ),
              const Spacer(),
              const Text('Welcome Aboard! 🎉', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('You are not in a mess yet. Choose an option below to get started.', style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
              const SizedBox(height: 40),
              
              // Option 1: Create
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMessScreen())),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: AppTheme.primaryIndigo.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryIndigo.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_home_rounded, color: AppTheme.primaryIndigo, size: 32),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start a New Mess', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            SizedBox(height: 4),
                            Text('You will be the Manager', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryIndigo, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Option 2: Join
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinMessScreen())),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.teal.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.group_add_rounded, color: Colors.teal, size: 32),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Join your Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            SizedBox(height: 4),
                            Text('Using a 6-digit invite code', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.teal, size: 20),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
