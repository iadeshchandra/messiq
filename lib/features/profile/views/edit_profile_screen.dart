import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl, _phoneCtrl, _presentCtrl, _permCtrl, _iceNameCtrl, _icePhoneCtrl;
  String? _selectedBloodGroup;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _presentCtrl = TextEditingController(text: widget.user.presentAddress);
    _permCtrl = TextEditingController(text: widget.user.permanentAddress);
    _iceNameCtrl = TextEditingController(text: widget.user.iceName);
    _icePhoneCtrl = TextEditingController(text: widget.user.icePhone);
    _selectedBloodGroup = widget.user.bloodGroup;
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'presentAddress': _presentCtrl.text.trim(),
        'permanentAddress': _permCtrl.text.trim(),
        'iceName': _iceNameCtrl.text.trim(),
        'icePhone': _icePhoneCtrl.text.trim(),
        'bloodGroup': _selectedBloodGroup,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), actions: [
        if (_isLoading) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()))
        else IconButton(icon: const Icon(Icons.check_rounded, color: AppTheme.primaryIndigo), onPressed: _saveProfile)
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryIndigo)),
            const SizedBox(height: 16),
            _buildField('Full Name', _nameCtrl, Icons.person_rounded),
            _buildField('Phone Number', _phoneCtrl, Icons.phone_rounded),
            _buildField('Present Address (Mess/Hostel)', _presentCtrl, Icons.location_city_rounded, lines: 2),
            _buildField('Permanent Address (Home)', _permCtrl, Icons.home_rounded, lines: 2),
            
            const SizedBox(height: 32),
            const Text('ICE Vault (In Case of Emergency)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: const Icon(Icons.bloodtype_rounded, color: Colors.red),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
              onChanged: (val) => setState(() => _selectedBloodGroup = val),
            ),
            const SizedBox(height: 16),
            _buildField('Emergency Contact Name (e.g. Father/Brother)', _iceNameCtrl, Icons.health_and_safety_rounded),
            _buildField('Emergency Contact Phone', _icePhoneCtrl, Icons.phone_in_talk_rounded),
          ],
        ),
      ),
    );
  }
}
