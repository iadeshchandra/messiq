import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_provider.dart';
import '../../auth/models/user_model.dart';

class HisabSheetScreen extends ConsumerWidget {
  final String messId;
  const HisabSheetScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hisabAsync = ref.watch(individualHisabProvider(messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Final Hisab Sheet', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.backgroundLight, elevation: 0),
      body: hisabAsync.when(
        data: (hisabList) {
          if (hisabList.isEmpty) return const Center(child: Text('No hisab data generated yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hisabList.length,
            itemBuilder: (context, index) {
              final hisab = hisabList[index];
              final UserModel member = hisab['member'];
              final double balance = hisab['balance'];
              final bool isDue = balance < 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    // Header
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
                              Text(isDue ? 'DUE' : 'ADVANCE', style: TextStyle(color: isDue ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('৳${balance.abs().toStringAsFixed(0)}', style: TextStyle(color: isDue ? Colors.red : Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                    // Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Total Meals Consumed', '${hisab['totalMeals'].toStringAsFixed(1)} Meals'),
                          _buildDetailRow('Meal Cost', '৳${hisab['mealCost'].toStringAsFixed(0)}'),
                          _buildDetailRow('Shared Utilities', '৳${hisab['utilityShare'].toStringAsFixed(0)}'),
                          const Divider(height: 24),
                          _buildDetailRow('Total Target Due', '৳${hisab['totalDue'].toStringAsFixed(0)}', isBold: true),
                          _buildDetailRow('Total Cash Paid', '৳${hisab['totalPaid'].toStringAsFixed(0)}', isBold: true, color: Colors.teal),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
