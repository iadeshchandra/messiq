import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/mess_repository.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String messId;
  const WaitingRoomScreen({super.key, required this.messId});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _isLoading = false;

  Future<void> _cancelRequest() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref.read(messRepositoryProvider).removeOrRejectMember(widget.messId, user.uid);
        // The AuthGate will automatically route them back to Selection Screen
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 100, color: Colors.orange),
              const SizedBox(height: 32),
              const Text('Waiting for Approval', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('Your request has been sent! The Mess Manager must review and accept your request before you can access the dashboard.', 
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _cancelRequest,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
