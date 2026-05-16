import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'member_ledger_screen.dart';
import '../../duties/controllers/duty_provider.dart'; // NEW IMPORT

// CHANGED TO ConsumerStatefulWidget TO LISTEN TO DUTIES
class MemberDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  bool _isLoading = false;

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
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(FirebaseFirestore.instance.collection('messes').doc(widget.messId).collection('members').doc(widget.member.uid));
        batch.set(FirebaseFirestore.instance.collection('users').doc(widget.member.uid), {'activeMessId': FieldValue.delete()}, SetOptions(merge: true));
        await batch.commit();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

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

  void _sendProfileReminder() async {
    setState(() => _isLoading = true);
    try {
      final notifRef = FirebaseFirestore.instance.collection('messes').doc(widget.messId).collection('notifications').doc();
      await notifRef.set({
        'title': '⚠️ Action Required: Update Profile',
        'body': 'Your Mess Manager has requested that you complete your profile. Your Phone Number and ICE (Emergency) details are strictly required for security and emergencies. Please tap "Profile" to update them immediately.',
        'targetUid': widget.member.uid,
        'createdAt': Timestamp.now(),
        'readBy': [],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    // NEW: Listen to duties to calculate the Karma Score
    final dutiesAsync = ref.watch(messDutiesProvider(widget.messId));

    double karmaScore = 100.0;
    int totalDuties = 0;
    int completedDuties = 0;

    if (dutiesAsync.value != null) {
      final memberDuties = dutiesAsync.value!.where((d) => d.assignedToUid == widget.member.uid).toList();
      totalDuties = memberDuties.length;
      completedDuties = memberDuties.where((d) => d.isCompleted).length;
      if (totalDuties > 0) {
        karmaScore = (completedDuties / totalDuties) * 100;
      }
    }

    // Determine color based on performance
    Color performanceColor = Colors.green;
    if (karmaScore < 50) performanceColor = Colors.redAccent;
    else if (karmaScore < 80) performanceColor = Colors.orange;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Member Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('messes').doc(widget.messId).collection('members').doc(widget.member.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final memberRoleData = snapshot.data!.data() as Map<String, dynamic>?;
          if (memberRoleData == null) return const Center(child: Text('Member data not found'));
          
          final currentRole = memberRoleData['role'] ?? 'member';
          
          String joinedDateString = 'Unknown';
          if (memberRoleData['joinedAt'] != null) {
            DateTime joinedDate = (memberRoleData['joinedAt'] as Timestamp).toDate();
            joinedDateString = joinedDate.toString().split(' ')[0]; 
          }

          bool isIncomplete = widget.member.icePhone == null || widget.member.icePhone!.isEmpty || widget.member.bloodGroup == null || widget.member.bloodGroup!.isEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1),
                  child: Text(widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(widget.member.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(widget.member.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: currentRole == 'manager' ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(currentRole.toUpperCase(), style: TextStyle(color: currentRole == 'manager' ? Colors.orange : Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('Joined: $joinedDateString', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberLedgerScreen(member: widget.member, messId: widget.messId))),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View Activity Ledger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryIndigo,
                      side: const BorderSide(color: AppTheme.primaryIndigo),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                      Text(_generateSmartOverview(currentRole), style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // NEW: THE KARMA SCORE (PERFORMANCE ENGINE)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: totalDuties == 0 ? 1.0 : karmaScore / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: performanceColor,
                            ),
                            Center(
                              child: Text(
                                '${karmaScore.toStringAsFixed(0)}%',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: performanceColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Performance Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Text(
                              totalDuties == 0 
                                ? 'No duties assigned yet. Score defaults to 100%.' 
                                : 'Completed $completedDuties out of $totalDuties assigned duties.',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (widget.isManager && isIncomplete) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                    child: Column(
                      children: [
                        const Text('Profile is missing critical emergency data.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendProfileReminder,
                          icon: const Icon(Icons.notifications_active_rounded, size: 18),
                          label: const Text('Send Reminder Alert'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

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
                
                if (widget.isManager) ...[
                  const SizedBox(height: 32),
                  const Align(alignment: Alignment.centerLeft, child: Text('Manager Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 16),
                  
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
