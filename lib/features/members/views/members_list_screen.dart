import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../../mess/repositories/mess_repository.dart';
import '../../auth/models/user_model.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends ConsumerWidget {
  final String messId;
  const MembersListScreen({super.key, required this.messId});

  void _shareInvite(BuildContext context, WidgetRef ref) async {
    final messData = await ref.read(messDetailsProvider(messId).future);
    if (messData != null) {
      Share.share("🏠 Join our workspace '${messData.name}' on MessIQ!\n\nDownload the app and enter this exact Invite Code to request access:\n\n👉 ${messData.inviteCode} 👈");
    }
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
          // THE VIRAL SHARE BUTTON
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryIndigo),
            onPressed: () => _shareInvite(context, ref),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          final statusDocs = statusDocsAsync.value ?? [];
          
          List<UserModel> pendingUsers = [];
          List<UserModel> activeUsers = [];

          // Sort users into the correct bucket based on status
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
                // PENDING APPROVALS SECTION (Only visible to Managers if there are requests)
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
