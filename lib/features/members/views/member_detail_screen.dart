import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../mess/models/mess_member_model.dart';

class MemberDetailScreen extends StatefulWidget {
  final UserModel member;
  final bool isManager;
  final String messId;

  const MemberDetailScreen({
    super.key,
    required this.member,
    required this.isManager,
    required this.messId,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  bool _isLoading = false;

  // Handles Kicking a Member
  void _kickMember(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to completely remove ${widget.member.name} from the mess?'),
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

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('messes').doc(widget.messId).collection('members').doc(widget.member.uid).delete();
        await FirebaseFirestore.instance.collection('users').doc(widget.member.uid).update({'activeMessId': FieldValue.delete()});
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Handles Promoting/Demoting a Member
  void _changeRole(String currentRole) async {
    final newRole = currentRole == 'manager' ? 'member' : 'manager';
    final actionText = newRole == 'manager' ? 'Promote to Manager' : 'Demote to Member';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText?'),
        content: Text('Do you want to change ${widget.member.name}\'s role to ${newRole.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('messes')
            .doc(widget.messId)
            .collection('members')
            .doc(widget.member.uid)
            .update({'role': newRole});
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Generates the "Smart Overview" text based on profile completeness
  String _generateSmartOverview(String role) {
    List<String> insights = [];
    
    insights.add("${widget.member.name.split(' ')[0]} is currently a ${role.toUpperCase()}.");

    bool hasAddress = widget.member.presentAddress != null && widget.member.presentAddress!.isNotEmpty;
    bool hasIce = widget.member.icePhone != null && widget.member.icePhone!.isNotEmpty;
    bool hasBlood = widget.member.bloodGroup != null && widget.member.bloodGroup!.isNotEmpty;

    if (hasAddress && hasIce && hasBlood) {
      insights.add("Their profile is 100% verified. ICE Vault is fully secured and ready for any emergency.");
    } else {
      insights.add("Their profile is incomplete.");
      if (!hasIce) insights.add("They have no emergency contact listed.");
      if (!hasBlood) insights.add("Blood group is missing.");
    }

    return insights.join(' ');
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Member Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Listen to the member's specific role document in real-time
        stream: FirebaseFirestore.instance.collection('messes').doc(widget.messId).collection('members').doc(widget.member.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final memberRoleData = snapshot.data!.data() as Map<String, dynamic>?;
          if (memberRoleData == null) return const Center(child: Text('Member data not found'));
          
          final currentRole = memberRoleData['role'] ?? 'member';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar Header
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                  child: Text(widget.member.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(widget.member.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentRole == 'manager' ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentRole.toUpperCase(),
                    style: TextStyle(color: currentRole == 'manager' ? Colors.orange : Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),

                // THE SMART OVERVIEW CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primaryIndigo.withOpacity(0.8), AppTheme.primaryIndigo]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppTheme.primaryIndigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          const Text('Smart Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          if (_isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _generateSmartOverview(currentRole),
                        style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contact Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact & Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                      const Divider(height: 32),
                      _buildInfoRow(Icons.phone_rounded, 'Phone Number', widget.member.phone),
                      _buildInfoRow(Icons.email_rounded, 'Email', widget.member.email),
                      _buildInfoRow(Icons.location_on_rounded, 'Present Address', widget.member.presentAddress),
                      _buildInfoRow(Icons.home_rounded, 'Permanent Address', widget.member.permanentAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // ICE Vault Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ICE Vault (Emergency)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(Icons.bloodtype_rounded, 'Blood Group', widget.member.bloodGroup),
                      _buildInfoRow(Icons.person_outline_rounded, 'Emergency Contact Name', widget.member.iceName),
                      _buildInfoRow(Icons.phone_in_talk_rounded, 'Emergency Contact Phone', widget.member.icePhone),
                    ],
                  ),
                ),
                
                // MANAGER TOOLS
                if (widget.isManager) ...[
                  const SizedBox(height: 32),
                  const Align(alignment: Alignment.centerLeft, child: Text('Manager Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 16),
                  
                  // Role Promotion/Demotion Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(currentRole == 'manager' ? Icons.arrow_downward_rounded : Icons.admin_panel_settings_rounded),
                      label: Text(currentRole == 'manager' ? 'Demote to Member' : 'Promote to Manager'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryIndigo,
                        side: const BorderSide(color: AppTheme.primaryIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _changeRole(currentRole),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Kick Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_remove_rounded),
                      label: const Text('Remove from Mess'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _kickMember(context),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
