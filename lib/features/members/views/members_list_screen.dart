import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
// CRITICAL: This import links to the file we just fixed above!
import 'member_detail_screen.dart'; 

class MembersListScreen extends ConsumerStatefulWidget {
  final String messId;
  const MembersListScreen({super.key, required this.messId});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  
  void _showBroadcastSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  const Text('Broadcast Announcement', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  const Text('Send an instant push notification to every member of the mess.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Announcement Title',
                      hintText: 'e.g., Urgent: Mess Meeting Tonight',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Message details...',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isSubmitting ? null : () async {
                        if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                          setSheetState(() => isSubmitting = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('messes')
                                .doc(widget.messId)
                                .collection('notifications')
                                .doc()
                                .set({
                              'title': '📢 ${titleCtrl.text.trim()}',
                              'body': bodyCtrl.text.trim(),
                              'targetUid': null, 
                              'targetRole': null,
                              'targetRoute': null, 
                              'createdAt': Timestamp.now(),
                              'readBy': [], 
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                            if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      icon: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.campaign_rounded),
                      label: Text(isSubmitting ? 'Sending...' : 'Send to Everyone', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));
    final memberStatusesAsync = ref.watch(messMemberStatusDocsProvider(widget.messId));
    final currentRoleAsync = ref.watch(currentMemberRoleProvider(widget.messId));

    final isManager = currentRoleAsync.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mess Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: AppTheme.primaryIndigo),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR Invite Code feature coming soon!')));
            },
          )
        ],
      ),
      floatingActionButton: isManager ? FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryIndigo,
        onPressed: () => _showBroadcastSheet(context),
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      body: membersAsync.when(
        data: (members) {
          return memberStatusesAsync.when(
            data: (statuses) {
              if (members.isEmpty) {
                return const Center(child: Text('No active members found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  
                  final statusDoc = statuses.firstWhere(
                    (s) => s['uid'] == member.uid,
                    orElse: () => {'role': 'member'},
                  );
                  final role = statusDoc['role']?.toString().toUpperCase() ?? 'MEMBER';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: role == 'MANAGER' ? Colors.orange : Colors.teal)),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () {
                        // The routing is completely fixed!
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member, isManager: isManager, messId: widget.messId)));
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading roles: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading directory: $e')),
      ),
    );
  }
}
