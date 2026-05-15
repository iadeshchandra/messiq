import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';

// This provider listens to Firebase to see if the user is part of ANY mess.
final activeMessProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collectionGroup('members')
      .where('uid', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      // Return the ID of the mess they belong to
      return snapshot.docs.first.reference.parent.parent?.id;
    }
    return null; // User is not in a mess
  });
});
