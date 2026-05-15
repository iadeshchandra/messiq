import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/mess_controller.dart';
import 'join_mess_screen.dart'; // IMPORTANT: Added import for cross-linking

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(messControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create a Workspace')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.domain_add_rounded, size: 80, color: AppTheme.primaryIndigo),
            const SizedBox(height: 24),
            
            // PROFESSIONAL UX: Extremely clear role definition
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('You will be the Manager', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'By creating a new Mess, you take charge. You will be responsible for inviting members, tracking daily expenses, and managing the monthly billing cycle.',
                    style: TextStyle(color: Colors.orange, height: 1.4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Workspace Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. The Developers Hub',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (_nameController.text.isNotEmpty) {
                  await ref.read(messControllerProvider.notifier).createMess(_nameController.text.trim());
                  if (context.mounted) Navigator.pop(context); 
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Workspace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            
            // PROFESSIONAL UX: The Cross-Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Wait, my friends already made one. ', style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JoinMessScreen())),
                  child: const Text('Join instead', style: TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
