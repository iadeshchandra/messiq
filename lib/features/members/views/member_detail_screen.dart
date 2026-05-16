import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';

class MemberDetailScreen extends StatelessWidget {
  final UserModel member;
  final bool isManager;
  final String messId;

  const MemberDetailScreen({super.key, required this.member, required this.isManager, required this.messId});

  void _kickMember(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove ${member.name} from the mess?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // 1. Delete from members subcollection
      await FirebaseFirestore.instance.collection('messes').doc(messId).collection('members').doc(member.uid).delete();
      // 2. Remove the activeMessId from their profile so they are booted to the Welcome screen
      await FirebaseFirestore.instance.collection('users').doc(member.uid).update({'activeMessId': FieldValue.delete()});
      if (context.mounted) Navigator.pop(context); // Go back to list
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryIndigo, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value != null && value.isNotEmpty ? value : 'Not provided', style: const TextStyle(fontSize: 16, color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(member.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
              child: Text(member.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact & Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                  const Divider(height: 32),
                  _buildInfoRow(Icons.phone_rounded, 'Phone Number', member.phone),
                  _buildInfoRow(Icons.email_rounded, 'Email', member.email),
                  _buildInfoRow(Icons.location_on_rounded, 'Present Address', member.presentAddress),
                  _buildInfoRow(Icons.home_rounded, 'Permanent Address', member.permanentAddress),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ICE Vault (Emergency)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 32, color: Colors.red),
                  _buildInfoRow(Icons.bloodtype_rounded, 'Blood Group', member.bloodGroup),
                  _buildInfoRow(Icons.person_outline_rounded, 'Emergency Contact Name', member.iceName),
                  _buildInfoRow(Icons.phone_in_talk_rounded, 'Emergency Contact Phone', member.icePhone),
                ],
              ),
            ),
            
            // MANAGER TOOL: Kick Button
            if (isManager) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_remove_rounded),
                  label: const Text('Remove from Mess'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _kickMember(context),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
