import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';

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
    // 1. Get the guaranteed authenticated user
    final user = ref.read(authStateProvider).value;
    
    // 2. Safety check to prevent the 'path.isNotEmpty' crash!
    if (user == null || user.uid.isEmpty) {
      throw Exception('Authentication error: Unable to find your User ID.');
    }

    // 3. Save the data using merge: true so it doesn't overwrite existing fields like activeMessId
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
