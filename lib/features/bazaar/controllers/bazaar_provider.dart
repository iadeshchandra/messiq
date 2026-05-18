import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/bazaar_item_model.dart';

final bazaarItemsStreamProvider = StreamProvider.family<List<BazaarItemModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('bazaar_checklist')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BazaarItemModel.fromMap(doc.data())).toList());
});

final bazaarControllerProvider = StateNotifierProvider<BazaarController, bool>((ref) {
  return BazaarController(ref: ref);
});

class BazaarController extends StateNotifier<bool> {
  final Ref _ref;
  BazaarController({required Ref ref}) : _ref = ref, super(false);

  Future<void> addItem({
    required String messId,
    required String name,
    required double quantity,
    required String unit,
    required double estimatedCost,
  }) async {
    state = true;
    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final id = firestore.collection('messes').doc(messId).collection('bazaar_checklist').doc().id;

      final item = BazaarItemModel(
        id: id,
        name: name,
        quantity: quantity,
        unit: unit,
        isBought: false,
        addedByName: user.displayName ?? 'Unknown', // FIXED: Firebase user name attribute
        estimatedCost: estimatedCost,
        createdAt: DateTime.now(),
      );

      await firestore.collection('messes').doc(messId).collection('bazaar_checklist').doc(id).set(item.toMap());
    } catch (e) { // FIXED: Replaced "neighborhoods" typo
      state = false;
    } finally {
      state = false;
    }
  }

  Future<void> toggleItemStatus(String messId, BazaarItemModel item) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('bazaar_checklist')
        .doc(item.id)
        .update({
      'isBought': !item.isBought,
      'boughtByName': !item.isBought ? (user.displayName ?? 'Unknown') : null, // FIXED: Firebase user name attribute
    });
  }

  Future<void> clearCompletedItems(String messId, List<BazaarItemModel> items) async {
    final batch = FirebaseFirestore.instance.batch();
    final completed = items.where((item) => item.isBought).toList();

    for (var item in completed) {
      final ref = FirebaseFirestore.instance.collection('messes').doc(messId).collection('bazaar_checklist').doc(item.id);
      batch.delete(ref);
    }
    await batch.commit();
  }
}
