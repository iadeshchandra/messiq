import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../mess/models/mess_model.dart';
import '../../mess/models/mess_member_model.dart';

final messDetailsProvider = StreamProvider.family<MessModel?, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) return MessModel.fromMap(doc.data()!);
    return null;
  });
});

final currentMemberRoleProvider = StreamProvider.family<MessMemberModel?, String>((ref, messId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('members').doc(user.uid).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) return MessMemberModel.fromMap(doc.data()!);
    return null;
  });
});

final messMembersDirectoryProvider = StreamProvider.family<List<UserModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('users').where('activeMessId', isEqualTo: messId).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
});

// NEW: Fetches the raw member documents so we can check who is 'pending' and who is 'approved'
final messMemberStatusDocsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('members').snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});
