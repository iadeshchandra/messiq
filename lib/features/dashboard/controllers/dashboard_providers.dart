import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../mess/models/mess_model.dart';
import '../../mess/models/mess_member_model.dart';

// Fetches the Mess Information (Name, Invite Code, etc.)
final messDetailsProvider = StreamProvider.family<MessModel?, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) return MessModel.fromMap(doc.data()!);
    return null;
  });
});

// Fetches the Current User's Role in this specific mess
final currentMemberRoleProvider = StreamProvider.family<MessMemberModel?, String>((ref, messId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('members')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (doc.exists && doc.data() != null) return MessMemberModel.fromMap(doc.data()!);
    return null;
  });
});
