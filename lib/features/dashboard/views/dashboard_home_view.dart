import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_providers.dart';

class DashboardHomeView extends ConsumerWidget {
  final String messId;
  const DashboardHomeView({super.key, required this.messId});

  // Dialog to allow Managers to rename the mess
  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Mess'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name', filled: true, fillColor: AppTheme.backgroundLight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('messes').doc(messId).update({'name': controller.text.trim()});
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messData = ref.watch(messDetailsProvider(messId));
    final memberData = ref.watch(currentMemberRoleProvider(messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: messData.when(
          data: (mess) => Row(
            children: [
              Text(mess?.name ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              // Show Edit button ONLY if the user is a Manager
              memberData.when(
                data: (member) => member?.role == 'manager'
                    ? IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey), onPressed: () => _showRenameDialog(context, mess!.name))
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error loading mess'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Finance Engine Workspace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Phase 4 tools will be built here.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            // Easy invite code copying for members
            messData.whenData((mess) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.primaryIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('Invite Code: ${mess?.inviteCode}', style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold, letterSpacing: 2)),
            )).value ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
