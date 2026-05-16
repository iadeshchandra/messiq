import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/duty_model.dart';

// Stream all duties for this mess, ordered by date
final messDutiesProvider = StreamProvider.family<List<DutyModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('duties')
      .orderBy('assignedDate', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => DutyModel.fromMap(doc.data(), doc.id)).toList());
});

final dutyControllerProvider = Provider((ref) => DutyController(ref: ref));

class DutyController {
  final Ref ref;
  DutyController({required this.ref});

  Future<void> addDuty({
    required String messId,
    required String title,
    required String assignedToUid,
    required String assignedToName,
    required DateTime assignedDate,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || title.trim().isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('duties').doc();
    
    final newDuty = DutyModel(
      id: docRef.id,
      title: title.trim(),
      assignedToUid: assignedToUid,
      assignedToName: assignedToName,
      assignedDate: assignedDate,
      isCompleted: false,
      addedByUid: user.uid,
      createdAt: DateTime.now(),
    );

    final batch = FirebaseFirestore.instance.batch();
    batch.set(docRef, newDuty.toMap());

    // AUTO-TRIGGER NOTIFICATION STRICTLY TO THE ASSIGNED USER
    final notifRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('notifications').doc();
    batch.set(notifRef, {
      'title': '🧹 New Duty Assigned',
      'body': 'You have been assigned to "$title" on ${assignedDate.toString().split(' ')[0]}. Check the Roster!',
      'targetUid': assignedToUid,
      'createdAt': Timestamp.now(),
      'readBy': [],
    });

    await batch.commit();
  }

  Future<void> toggleDutyStatus(String messId, String dutyId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('duties')
        .doc(dutyId)
        .update({'isCompleted': !currentStatus});
  }

  Future<void> deleteDuty(String messId, String dutyId) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('duties')
        .doc(dutyId)
        .delete();
  }
}
