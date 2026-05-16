import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../../mess/repositories/mess_repository.dart';
import '../../auth/models/user_model.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends ConsumerWidget {
  final String messId;
  const MembersListScreen({super.key, required this.messId});

  // NEW: Smart QR Code & Share Dialog
  void _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final messData = await ref.read(messDetailsProvider(messId).future);
    if (messData == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Invite Friends', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Have them scan this code:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2))
              ),
              child: QrImageView(
                data: messData.inviteCode,
                version: QrVersions.auto,
                size: 180.0,
                foregroundColor: AppTheme.primaryIndigo,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Or use this manual code:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              messData.inviteCode, 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.textDark)
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Share.share("🏠 Join our workspace '${messData.name}' on MessIQ!\n\nDownload the app and enter this exact Invite Code:\n\n👉 ${messData.inviteCode} 👈");
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share Link'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(messMembersDirectoryProvider(messId));
    final statusDocsAsync = ref.watch(messMemberStatusDocsProvider(messId));
    final currentUserRoleAsync = ref.watch(currentMemberRoleProvider(messId));

    final isManager = currentUserRoleAsync.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mess Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          // Triggers the QR popup
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryIndigo, size: 28),
            onPressed: () => _showInviteDialog(context, ref),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          final statusDocs = statusDocsAsync.value ?? [];
          
          List<UserModel> pendingUsers = [];
          List<UserModel> activeUsers = [];

          for (var user in users) {
            final doc = statusDocs.firstWhere((d) => d['uid'] == user.uid, orElse: () => {});
            if (doc['status'] == 'pending') {
              pendingUsers.add(user);
            } else {
              activeUsers.add(user);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PENDING APPROVALS SECTION
                if (isManager && pendingUsers.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.notification_important_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pendingUsers.map((user) => Card(
                    color: Colors.orange.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: Text(user.name[0], style: const TextStyle(color: Colors.orange))),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Requested to join'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: () => ref.read(messRepositoryProvider).removeOrRejectMember(messId, user.uid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                            onPressed: () => ref.read(messRepositoryProvider).approveMember(messId, user.uid),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const Divider(height: 32),
                ],

                // ACTIVE MEMBERS SECTION
                const Text('Active Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 12),
                ...activeUsers.map((user) {
                  final doc = statusDocs.firstWhere((d) => d['uid'] == user.uid, orElse: () => {});
                  final role = doc['role'] ?? 'member';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                        foregroundColor: AppTheme.primaryIndigo,
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(role.toUpperCase(), style: TextStyle(color: role == 'manager' ? Colors.orange : Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: user, isManager: isManager, messId: messId))),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
