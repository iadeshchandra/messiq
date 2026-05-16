import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _presentAddressCtrl;
  late TextEditingController _permanentAddressCtrl;
  late TextEditingController _iceNameCtrl;
  late TextEditingController _icePhoneCtrl;
  String _selectedBloodGroup = 'Unknown';

  final List<String> _bloodGroups = ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _presentAddressCtrl = TextEditingController();
    _permanentAddressCtrl = TextEditingController();
    _iceNameCtrl = TextEditingController();
    _icePhoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _iceNameCtrl.dispose();
    _icePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(profileControllerProvider).updateUserProfile(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        presentAddress: _presentAddressCtrl.text,
        permanentAddress: _permanentAddressCtrl.text,
        bloodGroup: _selectedBloodGroup == 'Unknown' ? '' : _selectedBloodGroup,
        iceName: _iceNameCtrl.text,
        icePhone: _icePhoneCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // THE FIX: Watch the custom user profile so we have access to phone/ICE data
    final userState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppTheme.primaryIndigo, size: 28),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: userState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          if (_nameCtrl.text.isEmpty && user.name.isNotEmpty) _nameCtrl.text = user.name;
          if (_phoneCtrl.text.isEmpty && user.phone != null) _phoneCtrl.text = user.phone!;
          if (_presentAddressCtrl.text.isEmpty && user.presentAddress != null) _presentAddressCtrl.text = user.presentAddress!;
          if (_permanentAddressCtrl.text.isEmpty && user.permanentAddress != null) _permanentAddressCtrl.text = user.permanentAddress!;
          if (_iceNameCtrl.text.isEmpty && user.iceName != null) _iceNameCtrl.text = user.iceName!;
          if (_icePhoneCtrl.text.isEmpty && user.icePhone != null) _icePhoneCtrl.text = user.icePhone!;
          
          if (_selectedBloodGroup == 'Unknown' && user.bloodGroup != null && user.bloodGroup!.isNotEmpty) {
            _selectedBloodGroup = user.bloodGroup!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo)),
                const SizedBox(height: 16),
                _buildTextField('Full Name', _nameCtrl, Icons.person_rounded),
                _buildTextField('Phone Number', _phoneCtrl, Icons.phone_rounded, type: TextInputType.phone),
                _buildTextField('Present Address (Mess/Hostel)', _presentAddressCtrl, Icons.location_city_rounded),
                _buildTextField('Permanent Address (Home)', _permanentAddressCtrl, Icons.home_rounded),
                
                const SizedBox(height: 32),
                const Text('ICE Vault (In Case of Emergency)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.bloodtype_rounded, color: Colors.redAccent),
                      border: InputBorder.none,
                    ),
                    items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                    onChanged: (val) => setState(() => _selectedBloodGroup = val!),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField('Emergency Contact Name', _iceNameCtrl, Icons.health_and_safety_rounded),
                _buildTextField('Emergency Contact Phone', _icePhoneCtrl, Icons.phone_in_talk_rounded, type: TextInputType.phone),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
