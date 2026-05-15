import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/mess_controller.dart';

class JoinMessScreen extends ConsumerStatefulWidget {
  const JoinMessScreen({super.key});

  @override
  ConsumerState<JoinMessScreen> createState() => _JoinMessScreenState();
}

class _JoinMessScreenState extends ConsumerState<JoinMessScreen> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(messControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join a Mess')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppTheme.primaryIndigo),
            const SizedBox(height: 16),
            const Text('Enter the 6-digit invite code provided by your Mess Manager.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (_codeController.text.length == 6) {
                    try {
                      await ref.read(messControllerProvider.notifier).joinMess(_codeController.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join request sent to Manager!')));
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Join Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
