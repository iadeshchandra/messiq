import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';

final activeMessProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  // Directly listen to the user's profile document for instant routing
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      return doc.data()!['activeMessId'] as String?;
    }
    return null;
  });
});
