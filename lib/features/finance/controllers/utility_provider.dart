import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/utility_bill_model.dart';

final utilityBillsStreamProvider = StreamProvider.family<List<UtilityBillModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('utility_bills')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UtilityBillModel.fromMap(doc.data())).toList());
});

final utilityControllerProvider = StateNotifierProvider<UtilityController, bool>((ref) {
  return UtilityController(ref: ref);
});

class UtilityController extends StateNotifier<bool> {
  final Ref _ref;
  UtilityController({required Ref ref}) : _ref = ref, super(false);

  Future<void> logAndSplitUtilityBill({
    required String messId,
    required String title,
    required String type,
    required double totalAmount,
  }) async {
    state = true;
    final firestore = FirebaseFirestore.instance;
    
    try {
      final currentUser = _ref.read(authStateProvider).value;
      if (currentUser == null) throw Exception("User session missing.");

      // 1. Fetch all active approved members to distribute costs fairly
      final membersSnapshot = await firestore
          .collection('messes')
          .doc(messId)
          .collection('members')
          .where('status', isEqualTo: 'approved')
          .get();

      final List<String> activeMemberUids = membersSnapshot.docs.map((doc) => doc.id).toList();
      if (activeMemberUids.isEmpty) throw Exception("No active members found to split bills.");

      // 2. Math Calculations
      final double share = totalAmount / activeMemberUids.length;
      final billId = firestore.collection('messes').doc(messId).collection('utility_bills').doc().id;

      final bill = UtilityBillModel(
        id: billId,
        title: title,
        type: type,
        totalAmount: totalAmount,
        perMemberShare: share,
        addedByUid: currentUser.uid,
        addedByName: currentUser.name,
        date: DateTime.now(),
        splitBetweenUids: activeMemberUids,
      );

      final batch = firestore.batch();

      // 3. Save Bill log record
      final billRef = firestore.collection('messes').doc(messId).collection('utility_bills').doc(billId);
      batch.set(billRef, bill.toMap());

      // 4. Inject structural balance shifts inside global expenses subcollection 
      // so the global Hisab Sheet updates instantly
      final globalExpenseRef = firestore.collection('messes').doc(messId).collection('expenses').doc();
      batch.set(globalExpenseRef, {
        'id': globalExpenseRef.id,
        'description': '$title ($type Bill Splitting)',
        'amount': totalAmount,
        'type': 'Utility',
        'addedByUid': currentUser.uid,
        'addedByName': currentUser.name,
        'date': Timestamp.now(),
        'note': 'Automatically auto-split equally among ${activeMemberUids.length} members.',
      });

      // 5. Broadcaster notifications payload record
      final notifRef = firestore.collection('messes').doc(messId).collection('notifications').doc();
      batch.set(notifRef, {
        'title': 'New Utility Bill Logged 🧾',
        'body': '${bill.type} bill of ৳${totalAmount.toStringAsFixed(0)} split equally. Your share: ৳${share.toStringAsFixed(1)}',
        'targetUid': null,
        'targetRole': null,
        'createdAt': Timestamp.now(),
        'readBy': [],
      });

      await batch.commit();
    } finally {
      state = false;
    }
  }
}
