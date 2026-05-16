import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/bazaar_provider.dart';

class BazaarListScreen extends ConsumerStatefulWidget {
  final String messId;
  const BazaarListScreen({super.key, required this.messId});

  @override
  ConsumerState<BazaarListScreen> createState() => _BazaarListScreenState();
}

class _BazaarListScreenState extends ConsumerState<BazaarListScreen> {
  final _itemController = TextEditingController();

  void _submitItem() async {
    if (_itemController.text.isNotEmpty) {
      await ref.read(bazaarControllerProvider).addItem(widget.messId, _itemController.text);
      _itemController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bazaarAsync = ref.watch(messBazaarProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Smart Bazaar List', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g., 5kg Rice, 1kg Onion...',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _submitItem(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _submitItem,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.primaryIndigo, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // List Section
          Expanded(
            child: bazaarAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('The list is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('Add groceries you need for the mess.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Sort: Unpurchased items at the top, purchased at the bottom
                final sortedItems = List.of(items)..sort((a, b) {
                  if (a.isPurchased == b.isPurchased) return b.createdAt.compareTo(a.createdAt);
                  return a.isPurchased ? 1 : -1;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: item.isPurchased ? Colors.grey.shade50 : Colors.white,
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isPurchased,
                          activeColor: Colors.teal,
                          onChanged: (_) => ref.read(bazaarControllerProvider).toggleItemStatus(widget.messId, item.id, item.isPurchased),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: item.isPurchased ? Colors.grey : AppTheme.textDark,
                            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text('Added by ${item.addedByName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => ref.read(bazaarControllerProvider).deleteItem(widget.messId, item.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
