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
                    icon: const Icon(Icons.logout),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  )
                ],
              ),
              const Spacer(),
              const Text(
                'Let\'s get started',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Create a new shared living space or join an existing one.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              // Bento Grid Card 1
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMessScreen())),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.primaryIndigo.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_home_rounded, color: AppTheme.primaryIndigo, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create new Mess', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('You will be the Manager', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bento Grid Card 2
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinMessScreen())),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.group_add_rounded, color: Colors.orange, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Join existing Mess', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Using a 6-digit invite code', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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
