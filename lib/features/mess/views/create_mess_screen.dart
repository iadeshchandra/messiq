import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/mess_controller.dart';
import 'join_mess_screen.dart';

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
      appBar: AppBar(title: const Text('Start a New Mess')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.home_work_rounded, size: 80, color: AppTheme.primaryIndigo),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withOpacity(0.05),
                border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.waving_hand_rounded, color: AppTheme.primaryIndigo),
                      SizedBox(width: 8),
                      Text('Starting a new journey? 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'By creating this mess, you will become the Manager. You\'ll handle the daily Hisab, Bazaar lists, and add members.',
                    style: TextStyle(color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Mess / Hostel Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Dhaka Boys Hostel',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (_nameController.text.isNotEmpty) {
                  try {
                    await ref.read(messControllerProvider.notifier).createMess(_nameController.text.trim());
                    if (context.mounted) {
                      // THE FIX: Destroys the Create screen and reveals AuthGate (Dashboard)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    }
                  }
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
                : const Text('Create Mess', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('Did your friends already create one?', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JoinMessScreen())),
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('Join an Existing Mess'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryIndigo,
                      side: const BorderSide(color: AppTheme.primaryIndigo),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
