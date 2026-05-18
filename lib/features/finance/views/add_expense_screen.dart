import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_provider.dart';
import '../../ai_insights/controllers/ocr_scanner_provider.dart'; // NEW: The AI Scanner Import

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddExpenseScreen({super.key, required this.messId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController(); // The Note Controller
  String _type = 'Bazaar';
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  
  // NEW: State for AI Scanner
  bool _isScanning = false; 

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // NEW: Trigger the AI Scanner
  Future<void> _startAiScan() async {
    setState(() => _isScanning = true);
    
    final ocrService = ref.read(ocrScannerProvider);
    final scannedTotal = await ocrService.scanReceiptForTotal();
    
    if (mounted) {
      setState(() => _isScanning = false);

      if (scannedTotal != null) {
        _amountCtrl.text = scannedTotal.toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Found Total: ৳${scannedTotal.toStringAsFixed(0)}'), backgroundColor: Colors.teal),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect a clear total amount. Please enter manually.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.backgroundLight, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: AI RECEIPT SCANNER BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _startAiScan,
                icon: _isScanning 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryIndigo))
                    : const Icon(Icons.document_scanner_rounded),
                label: Text(_isScanning ? 'AI Scanning Receipt...' : 'Smart Scan Bazaar Slip'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryIndigo,
                  side: const BorderSide(color: AppTheme.primaryIndigo, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Expense Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Bazaar'),
                    value: 'Bazaar',
                    groupValue: _type,
                    onChanged: (val) => setState(() => _type = val!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryIndigo,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Utility'),
                    value: 'Utility',
                    groupValue: _type,
                    onChanged: (val) => setState(() => _type = val!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryIndigo,
                  ),
                ),
              ],
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

            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'e.g., Rice, Vegetables, Internet Bill', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),

            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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

            // ACCOUNTABILITY NOTE UI
            const Text('Manager Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'e.g., Purchased from fresh market', filled: true, fillColor: Colors.white, prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _isLoading ? null : () async {
                  if (_amountCtrl.text.isNotEmpty && _descCtrl.text.isNotEmpty) {
                    setState(() => _isLoading = true);
                    try {
                      await ref.read(financeControllerProvider).addExpense(
                        widget.messId, 
                        double.parse(_amountCtrl.text), 
                        _descCtrl.text.trim(), 
                        _type, 
                        _date,
                        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(), // Send the note!
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense logged securely!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
