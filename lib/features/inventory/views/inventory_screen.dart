import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final String messId;
  const InventoryScreen({super.key, required this.messId});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _burnCtrl = TextEditingController();
  String _selectedUnit = 'kg';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _burnCtrl.dispose();
    super.dispose();
  }

  void _showAddStockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Log New Kitchen Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Item Name (e.g. Rice, Oil)', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Total Qty', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        items: ['kg', 'L', 'pcs'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => _selectedUnit = val!),
                        decoration: InputDecoration(filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _burnCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Est. Daily Burn (e.g. 1.5 kg/day)', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      if (_nameCtrl.text.isNotEmpty && _qtyCtrl.text.isNotEmpty && _burnCtrl.text.isNotEmpty) {
                        await ref.read(inventoryControllerProvider.notifier).addOrRestockItem(
                          messId: widget.messId,
                          name: _nameCtrl.text.trim(),
                          quantity: double.tryParse(_qtyCtrl.text.trim()) ?? 0.0,
                          unit: _selectedUnit,
                          dailyBurn: double.tryParse(_burnCtrl.text.trim()) ?? 0.0,
                        );
                        _nameCtrl.clear();
                        _qtyCtrl.clear();
                        _burnCtrl.clear();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add to Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider(widget.messId));
    final isLoading = ref.watch(inventoryControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Smart Kitchen Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          inventoryAsync.when(
            data: (items) => IconButton(
              icon: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded, color: Colors.orange),
              tooltip: 'Simulate Daily Consumption',
              onPressed: () => ref.read(inventoryControllerProvider.notifier).processDailyConsumption(widget.messId, items),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: _showAddStockSheet,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Log Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Kitchen is empty!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Log your bulk purchases here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (ctx, idx) {
              final item = items[idx];
              final progress = item.initialQuantity > 0 ? (item.currentQuantity / item.initialQuantity) : 0.0;
              final color = item.isCritical ? Colors.redAccent : Colors.teal;

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => ref.read(inventoryControllerProvider.notifier).deleteItem(widget.messId, item.id),
                          )
                        ],
                      ),
                      Text('${item.currentQuantity.toStringAsFixed(1)} ${item.unit} left (Burns ~${item.estimatedDailyBurn} ${item.unit}/day)', 
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: AppTheme.backgroundLight,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // AI Status Indicator
                      Row(
                        children: [
                          Icon(item.isCritical ? Icons.warning_rounded : Icons.check_circle_rounded, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.isCritical 
                                ? 'Critical: ${item.daysRemaining} days left! AI auto-injected to Bazaar.'
                                : 'Safe: ~${item.daysRemaining} days of supply left.',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
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
}
