import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_provider.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../../auth/models/user_model.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddPaymentScreen({super.key, required this.messId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController(); // NEW: The Note Controller
  UserModel? _selectedMember;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Log Deposit', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.backgroundLight, elevation: 0),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return const Center(child: Text('No members found.'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Member', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: DropdownButtonFormField<UserModel>(
                    value: _selectedMember,
                    decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.person, color: AppTheme.primaryIndigo)),
                    items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                    onChanged: (val) => setState(() => _selectedMember = val),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text('Amount (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.attach_money, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),

                const Text('Deposit Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.white,
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryIndigo),
                  title: Text(_date.toString().split(' ')[0]),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 20),

                // NEW: ACCOUNTABILITY NOTE UI
                const Text('Manager Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: 'e.g., Handed via bKash, received by Rahim', filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _isLoading ? null : () async {
                      if (_selectedMember != null && _amountCtrl.text.isNotEmpty) {
                        setState(() => _isLoading = true);
                        try {
                          await ref.read(financeControllerProvider).addPayment(
                            widget.messId, 
                            _selectedMember!.uid, 
                            double.parse(_amountCtrl.text), 
                            _date,
                            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(), // Send the note!
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deposit logged securely!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
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
