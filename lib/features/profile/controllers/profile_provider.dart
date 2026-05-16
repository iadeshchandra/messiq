import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

// NEW: This fetches the custom UserModel from Firestore so we can see addresses/ICE data
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);

  return FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['uid'] = doc.id; // Safe ID injection
      return UserModel.fromMap(data);
    }
    return null;
  });
});

final profileControllerProvider = Provider((ref) => ProfileController(ref: ref));

class ProfileController {
  final Ref ref;
  ProfileController({required this.ref});

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    required String presentAddress,
    required String permanentAddress,
    required String bloodGroup,
    required String iceName,
    required String icePhone,
  }) async {
    final user = ref.read(authStateProvider).value;
    
    if (user == null || user.uid.isEmpty) {
      throw Exception('Authentication error: Unable to find your User ID.');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'phone': phone.trim(),
      'presentAddress': presentAddress.trim(),
      'permanentAddress': permanentAddress.trim(),
      'bloodGroup': bloodGroup.trim(),
      'iceName': iceName.trim(),
      'icePhone': icePhone.trim(),
    }, SetOptions(merge: true));
  }
}
