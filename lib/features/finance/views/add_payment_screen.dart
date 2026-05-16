import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../controllers/finance_provider.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddPaymentScreen({super.key, required this.messId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountCtrl = TextEditingController();
  String? _selectedMemberUid;

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _selectedMemberUid == null) return;
    try {
      await ref.read(financeControllerProvider.notifier).addPayment(
        widget.messId,
        _selectedMemberUid!,
        double.parse(_amountCtrl.text.trim()),
        DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));
    final isLoading = ref.watch(financeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Member Deposit')),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return const Center(child: Text('No members found.'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedMemberUid,
                  hint: const Text('Select Member'),
                  decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  items: members.map((m) => DropdownMenuItem(value: m.uid, child: Text(m.name))).toList(),
                  onChanged: (val) => setState(() => _selectedMemberUid = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'Deposit Amount (৳)', prefixIcon: const Icon(Icons.payments_rounded), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Deposit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
