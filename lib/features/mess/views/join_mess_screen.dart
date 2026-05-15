import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/mess_controller.dart';
import 'qr_scanner_screen.dart';
import 'create_mess_screen.dart'; // IMPORTANT: Added import for cross-linking

class JoinMessScreen extends ConsumerStatefulWidget {
  const JoinMessScreen({super.key});

  @override
  ConsumerState<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends ConsumerState<JoinMessScreen> {
  final _codeController = TextEditingController();

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scannedCode != null) {
      _codeController.text = scannedCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(messControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join a Workspace')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // PROFESSIONAL UX: Explicit context and instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_add_rounded, color: AppTheme.primaryIndigo),
                      SizedBox(width: 8),
                      Text('Join an Existing Mess', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryIndigo)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('You are requesting to join a workspace managed by someone else. You need their permission to enter.', style: TextStyle(height: 1.5, color: Colors.black87)),
                  SizedBox(height: 12),
                  Text('• Ask your Manager for the 6-digit Invite Code.', style: TextStyle(height: 1.5, color: Colors.black54)),
                  Text('• Or tap the icon below to scan their QR code.', style: TextStyle(height: 1.5, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            GestureDetector(
              onTap: _openScanner,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 50, color: AppTheme.primaryIndigo),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to Scan QR', style: TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
            const Align(alignment: Alignment.centerLeft, child: Text('Or enter code manually:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (_codeController.text.length == 6) {
                    try {
                      await ref.read(messControllerProvider.notifier).joinMess(_codeController.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context); 
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
                  : const Text('Send Join Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            
            // PROFESSIONAL UX: The Cross-Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Want to start your own? ', style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateMessScreen())),
                  child: const Text('Create a Mess', style: TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
