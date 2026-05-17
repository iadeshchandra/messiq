import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_provider.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../../auth/models/user_model.dart';
import '../services/pdf_service.dart';

class HisabSheetScreen extends ConsumerStatefulWidget {
  final String messId;
  const HisabSheetScreen({super.key, required this.messId});

  @override
  ConsumerState<HisabSheetScreen> createState() => _HisabSheetScreenState();
}

class _HisabSheetScreenState extends ConsumerState<HisabSheetScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    setState(() => _isExporting = true);
    try {
      final messData = await ref.read(messDetailsProvider(widget.messId).future);
      final hisabSummary = ref.read(hisabSummaryProvider(widget.messId));
      final hisabList = ref.read(individualHisabProvider(widget.messId));

      if (messData == null || hisabList.isEmpty) throw Exception("No data available to export.");

      final File pdfFile = await PdfService.generateHisabPdf(
        messName: messData.name,
        messId: widget.messId,
        hisabSummary: hisabSummary,
        hisabList: hisabList,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportSuccessSheet(context, pdfFile);
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showExportSuccessSheet(BuildContext context, File pdfFile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Hisab PDF Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Your monthly statement has been generated successfully.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download to Device'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  try {
                    final downloadDir = Directory('/storage/emulated/0/Download');
                    if (await downloadDir.exists()) {
                      final newPath = '${downloadDir.path}/${pdfFile.path.split('/').last}';
                      await pdfFile.copy(newPath);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully to Downloads!'), backgroundColor: Colors.green));
                      }
                    } else {
                      throw Exception("Downloads folder not found.");
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download: Try using Share to save.'), backgroundColor: Colors.orange));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share to WhatsApp / Group'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryIndigo, side: const BorderSide(color: AppTheme.primaryIndigo), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Share.shareXFiles([XFile(pdfFile.path)], text: 'MessIQ Hisab Statement generated on ${DateTime.now().toString().split(' ')[0]}');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hisabList = ref.watch(individualHisabProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Final Hisab Sheet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          if (_isExporting)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryIndigo),
              onPressed: () => _exportPdf(context, ref),
            )
        ],
      ),
      body: hisabList.isEmpty
          ? const Center(child: Text('No hisab data generated yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hisabList.length,
              itemBuilder: (context, index) {
                final hisab = hisabList[index];
                final UserModel member = hisab['member'];
                
                // FIXED: Safety checks and matching correct math variables
                final double balance = hisab['balance'] ?? 0.0;
                final double totalMeals = hisab['totalMeals'] ?? 0.0;
                final double mealCost = hisab['mealCost'] ?? 0.0;
                final double individualUtility = hisab['individualUtility'] ?? 0.0;
                final double totalCost = hisab['totalCost'] ?? 0.0;
                final double deposits = hisab['deposits'] ?? 0.0;
                
                final bool isDue = balance < 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: isDue ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: isDue ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), child: Text(member.name[0].toUpperCase(), style: TextStyle(color: isDue ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 16),
                            Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(isDue ? 'DUE TO MESS' : 'ADVANCE', style: TextStyle(color: isDue ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text('৳${balance.abs().toStringAsFixed(0)}', style: TextStyle(color: isDue ? Colors.red : Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailRow('Total Meals Consumed', '${totalMeals.toStringAsFixed(1)} Meals'),
                            _buildDetailRow('Meal Cost', '৳${mealCost.toStringAsFixed(0)}'),
                            _buildDetailRow('Shared Utilities', '৳${individualUtility.toStringAsFixed(0)}'),
                            const Divider(height: 24),
                            _buildDetailRow('Total Target Due', '৳${totalCost.toStringAsFixed(0)}', isBold: true),
                            _buildDetailRow('Total Cash Paid', '৳${deposits.toStringAsFixed(0)}', isBold: true, color: Colors.teal),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black87 : Colors.grey, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
