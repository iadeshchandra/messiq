import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/bazaar_provider.dart';
import '../models/bazaar_item_model.dart';

class BazaarListScreen extends ConsumerStatefulWidget {
  final String messId;
  const BazaarListScreen({super.key, required this.messId});

  @override
  ConsumerState<BazaarListScreen> createState() => _BazaarListScreenState();
}

class _BazaarListScreenState extends ConsumerState<BazaarListScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedUnit = 'kg';

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Grocery / Bazaar Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Item Name (e.g., Rice, Fish, Milk)', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Qty', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items: ['kg', 'litre', 'piece', 'packet', 'bunch'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => _selectedUnit = val ?? 'kg'),
                      decoration: InputDecoration(filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Estimated Cost (৳ Optional)', prefixText: '৳ ', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    if (_nameController.text.isNotEmpty && _qtyController.text.isNotEmpty) {
                      await ref.read(bazaarControllerProvider.notifier).addItem(
                        messId: widget.messId,
                        name: _nameController.text.trim(),
                        quantity: double.tryParse(_qtyController.text.trim()) ?? 1.0,
                        unit: _selectedUnit,
                        estimatedCost: double.tryParse(_costController.text.trim()) ?? 0.0,
                      );
                      _nameController.clear();
                      _qtyController.clear();
                      _costController.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add to Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(bazaarItemsStreamProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Bazaar Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        actions: [
          itemsAsync.when(
            data: (items) {
              final hasCompleted = items.any((i) => i.isBought);
              if (!hasCompleted) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                tooltip: 'Clear Completed Items',
                onPressed: () => ref.read(bazaarControllerProvider.notifier).clearCompletedItems(widget.messId, items),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: _showAddItemSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Checklist is empty!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Add items needed for upcoming meals.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, idx) {
              final item = items[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: item.isBought ? Colors.grey.shade100 : Colors.white,
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      item.isBought ? Icons.check_box_rounded : Icons.checkbox_shadow,
                      color: item.isBought ? Colors.teal : Colors.grey,
                      size: 26,
                    ),
                    onPressed: () => ref.read(bazaarControllerProvider.notifier).toggleItemStatus(widget.messId, item),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.isBought ? Colors.grey : AppTheme.textDark,
                      decoration: item.isBought ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity} ${item.unit} • Asked by ${item.addedByName}${item.boughtByName != null ? ' • Bought by ${item.boughtByName}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: item.estimatedCost > 0
                      ? Text(
                          '৳${item.estimatedCost.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.isBought ? Colors.grey : Colors.teal,
                          ),
                        )
                      : null,
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
