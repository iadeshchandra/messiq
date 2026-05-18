import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/inventory_item_model.dart';

final inventoryStreamProvider = StreamProvider.family<List<InventoryItemModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('inventory')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => InventoryItemModel.fromMap(doc.data(), doc.id)).toList());
});

final inventoryControllerProvider = StateNotifierProvider<InventoryController, bool>((ref) {
  return InventoryController(ref: ref);
});

class InventoryController extends StateNotifier<bool> {
  final Ref ref;
  InventoryController({required this.ref}) : super(false);

  // Manually add new stock to the kitchen
  Future<void> addOrRestockItem({
    required String messId,
    required String name,
    required double quantity,
    required String unit,
    required double dailyBurn,
  }) async {
    state = true;
    try {
      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('inventory').doc();
      
      final newItem = InventoryItemModel(
        id: docRef.id,
        name: name,
        currentQuantity: quantity,
        initialQuantity: quantity,
        unit: unit,
        estimatedDailyBurn: dailyBurn,
        alertTriggered: false, // Reset alert on fresh stock
        lastUpdated: DateTime.now(),
      );

      await docRef.set(newItem.toMap());
    } finally {
      state = false;
    }
  }

  // Deduct daily consumption and trigger AI Bazaar injection if critical
  Future<void> processDailyConsumption(String messId, List<InventoryItemModel> currentInventory) async {
    state = true;
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    bool aiActionTaken = false;

    for (var item in currentInventory) {
      double newQty = item.currentQuantity - item.estimatedDailyBurn;
      if (newQty < 0) newQty = 0;

      int daysLeft = newQty > 0 && item.estimatedDailyBurn > 0 
          ? (newQty / item.estimatedDailyBurn).floor() 
          : 0;

      bool triggerAlert = daysLeft <= 2 && !item.alertTriggered && newQty > 0;

      final itemRef = firestore.collection('messes').doc(messId).collection('inventory').doc(item.id);
      
      batch.update(itemRef, {
        'currentQuantity': newQty,
        'lastUpdated': Timestamp.now(),
        if (triggerAlert) 'alertTriggered': true,
      });

      // AI INTERVENTION: Auto-inject into Bazaar Checklist
      if (triggerAlert) {
        aiActionTaken = true;
        final bazaarRef = firestore.collection('messes').doc(messId).collection('bazaar_checklist').doc();
        batch.set(bazaarRef, {
          'id': bazaarRef.id,
          'name': item.name,
          'quantity': item.initialQuantity, // Auto-order the usual bulk amount
          'unit': item.unit,
          'isBought': false,
          'addedByName': 'Smart Inventory AI 🤖', // Clearly mark it as AI generated
          'estimatedCost': 0.0,
          'createdAt': Timestamp.now(),
        });

        // Notify the manager
        final notifRef = firestore.collection('messes').doc(messId).collection('notifications').doc();
        batch.set(notifRef, {
          'title': 'AI Restock Alert ⚠️',
          'body': '${item.name} will run out in $daysLeft days! It has been auto-added to the Bazaar list.',
          'createdAt': Timestamp.now(),
          'readBy': [],
        });
      }
    }

    await batch.commit();
    state = false;
  }

  Future<void> deleteItem(String messId, String itemId) async {
    await FirebaseFirestore.instance.collection('messes').doc(messId).collection('inventory').doc(itemId).delete();
  }
}
