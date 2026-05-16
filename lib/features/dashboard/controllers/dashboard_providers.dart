import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../mess/models/mess_model.dart';
import '../../mess/models/mess_member_model.dart';

// Fetches the Mess Information (Name, Invite Code, etc.)
final messDetailsProvider = StreamProvider.family<MessModel?, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id; // Safe ID injection
      return MessModel.fromMap(data);
    }
    return null;
  });
});

// Fetches the Current User's Role in this specific mess
final currentMemberRoleProvider = StreamProvider.family<MessMemberModel?, String>((ref, messId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('members').doc(user.uid).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['uid'] = doc.id; // Safe ID injection
      return MessMemberModel.fromMap(data);
    }
    return null;
  });
});

// Fetches all users who belong to this specific mess for the Directory
final messMembersDirectoryProvider = StreamProvider.family<List<UserModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('users').where('activeMessId', isEqualTo: messId).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // CRITICAL FIX: Force the real document ID into the UID field so it is never empty
            data['uid'] = doc.id; 
            return UserModel.fromMap(data);
          }).toList());
});

// Fetches the raw member documents so we can check who is 'pending' and who is 'approved'
final messMemberStatusDocsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('members').snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // CRITICAL FIX: Force the real document ID
            data['uid'] = doc.id; 
            return data;
          }).toList());
});
