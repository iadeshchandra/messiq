import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final String messId;
  const ProfileScreen({super.key, required this.messId});

  Widget _buildInfoTile(IconData icon, String title, String? value, {Color iconColor = AppTheme.primaryIndigo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value != null && value.isNotEmpty ? value : 'Not added yet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final memberData = ref.watch(currentMemberRoleProvider(messId));

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
          final userModel = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryIndigo.withOpacity(0.2),
                  child: Text(userModel.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                ),
                const SizedBox(height: 16),
                Text(userModel.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(userModel.email, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: userModel))),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Full Profile'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(height: 30),
                      _buildInfoTile(Icons.phone_rounded, 'Phone', userModel.phone),
                      _buildInfoTile(Icons.location_on_rounded, 'Present Address', userModel.presentAddress),
                      _buildInfoTile(Icons.home_rounded, 'Permanent Address', userModel.permanentAddress),
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
                      const Text('ICE Vault (Emergency)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      const Divider(height: 30),
                      _buildInfoTile(Icons.bloodtype_rounded, 'Blood Group', userModel.bloodGroup, iconColor: Colors.red),
                      _buildInfoTile(Icons.health_and_safety_rounded, 'ICE Contact Name', userModel.iceName, iconColor: Colors.red),
                      _buildInfoTile(Icons.phone_in_talk_rounded, 'ICE Phone Number', userModel.icePhone, iconColor: Colors.red),
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
