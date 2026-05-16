import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends ConsumerWidget {
  final String messId;
  const MembersListScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(messId));
    final currentUserRoleAsync = ref.watch(currentMemberRoleProvider(messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mess Members', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return const Center(child: Text('No members found.'));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                    foregroundColor: AppTheme.primaryIndigo,
                    child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member.phone ?? 'No phone added', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: member.bloodGroup != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(member.bloodGroup!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    // Open detailed profile and pass the current user's role so we know if they can kick them
                    final isManager = currentUserRoleAsync.value?.role == 'manager';
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member, isManager: isManager, messId: messId)));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
