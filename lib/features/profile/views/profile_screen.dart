import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String messId;
  const ProfileScreen({super.key, required this.messId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _editNameDialog(String currentName, String uid) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(filled: true, fillColor: AppTheme.backgroundLight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({'name': controller.text.trim()});
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
    final authUser = ref.watch(authStateProvider).value;
    final memberData = ref.watch(currentMemberRoleProvider(widget.messId));

    if (authUser == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                  child: Text(
                    userData?['name']?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(userData?['name'] ?? 'Loading...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20, color: AppTheme.primaryIndigo),
                      onPressed: () => _editNameDialog(userData?['name'] ?? '', authUser.uid),
                    ),
                  ],
                ),
                Text(userData?['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                
                const SizedBox(height: 40),
                
                // Mess Details Card (Read-Only Info)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Workspace Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                      const Divider(height: 30),
                      
                      // Role Display
                      const Text('Your Role', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      memberData.when(
                        data: (member) => Row(
                          children: [
                            Icon(member?.role == 'manager' ? Icons.admin_panel_settings_rounded : Icons.person_rounded, color: member?.role == 'manager' ? Colors.orange : Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Text((member?.role ?? 'Member').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('Error'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Read-Only Mess ID
                      const Text('Secure Mess ID (System Generated)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.messId, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 14))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
