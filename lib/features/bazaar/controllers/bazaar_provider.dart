import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/bazaar_item_model.dart';

// Stream all bazaar items for this mess, ordered by newest first
final messBazaarProvider = StreamProvider.family<List<BazaarItemModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('bazaarItems')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BazaarItemModel.fromMap(doc.data(), doc.id)).toList());
});

final bazaarControllerProvider = Provider((ref) => BazaarController(ref: ref));

class BazaarController {
  final Ref ref;
  BazaarController({required this.ref});

  Future<void> addItem(String messId, String itemName) async {
    if (itemName.trim().isEmpty) return;
    
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Fetch the user's name from Firestore to tag who added the item
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Member';

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('bazaarItems').doc();
    
    final newItem = BazaarItemModel(
      id: docRef.id,
      name: itemName.trim(),
      addedByUid: user.uid,
      addedByName: userName,
      createdAt: DateTime.now(),
    );

    await docRef.set(newItem.toMap());
  }

  Future<void> toggleItemStatus(String messId, String itemId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('bazaarItems')
        .doc(itemId)
        .update({'isPurchased': !currentStatus});
  }

  Future<void> deleteItem(String messId, String itemId) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('bazaarItems')
        .doc(itemId)
        .delete();
  }
}
