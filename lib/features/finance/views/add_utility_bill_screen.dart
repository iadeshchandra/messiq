import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/utility_provider.dart';

class AddUtilityBillScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddUtilityBillScreen({super.key, required this.messId});

  @override
  ConsumerState<AddUtilityBillScreen> createState() => _AddUtilityBillScreenState();
}

class _AddUtilityBillScreenState extends ConsumerState<AddUtilityBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedType = 'WiFi';
  final List<String> _utilityTypes = ['WiFi', 'Electricity', 'Gas', 'Maid/Khala', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(utilityControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Split Utility Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppTheme.primaryIndigo),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This utility bill will be automatically divided equally among all approved mess members.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('Select Bill Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: _utilityTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 24),

              const Text('Bill Title / Month', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g., WiFi Bill May 2026',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),

              const Text('Total Amount (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryIndigo),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '৳ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                  if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await ref.read(utilityControllerProvider.notifier).logAndSplitUtilityBill(
                          messId: widget.messId,
                          title: _titleController.text.trim(),
                          type: _selectedType,
                          totalAmount: double.parse(_amountController.text.trim()),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bill split successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add & Split Equally', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
