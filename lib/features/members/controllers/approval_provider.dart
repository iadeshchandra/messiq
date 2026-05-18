import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';

// Streams the raw member subcollection documents where status is pending
final pendingRequestsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('members')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .asyncMap((snapshot) async {
        List<Map<String, dynamic>> pendingUsers = [];

        // FIXED: Changed 'const doc' to 'final doc' 
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final uid = data['uid'];

          // Fetch the full user details profile to show their name
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userModel = UserModel.fromMap(userDoc.data()!);
            pendingUsers.add({
              'uid': uid,
              'user': userModel,
              'joinedAt': data['joinedAt'],
            });
          }
        }
        return pendingUsers;
      });
});
