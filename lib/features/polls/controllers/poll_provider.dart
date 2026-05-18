import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/poll_model.dart';

final messPollsProvider = StreamProvider.family<List<PollModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('polls')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PollModel.fromMap(doc.data(), doc.id)).toList());
});

// FIXED: Converted from Provider to StateNotifierProvider
final pollControllerProvider = StateNotifierProvider<PollController, bool>((ref) {
  return PollController(ref: ref);
});

class PollController extends StateNotifier<bool> {
  final Ref ref;
  PollController({required this.ref}) : super(false); // FIXED: Added StateNotifier initialization

  // FIXED: Renamed to match the UI and added named parameters
  Future<void> createCustomMealPoll({
    required String messId, 
    required String question, 
    required List<String> options, 
    DateTime? expiresAt
  }) async {
    state = true; // Start loading
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null || question.isEmpty || options.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Member';

      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('polls').doc();
      final validOptions = options.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final newPoll = PollModel(
        id: docRef.id,
        question: question.trim(),
        options: validOptions,
        votes: {},
        addedByUid: user.uid,
        addedByName: userName,
        createdAt: DateTime.now(),
        isActive: true,
        expiresAt: expiresAt, 
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, newPoll.toMap());

      final notifRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('notifications').doc();
      batch.set(notifRef, {
        'title': 'New Poll Created 📊',
        'body': '$userName asked: "$question". Tap to cast your vote!',
        'targetRoute': 'polls', 
        'createdAt': Timestamp.now(),
        'readBy': [],
      });

      await batch.commit();
    } finally {
      state = false; // Stop loading
    }
  }

  // FIXED: Renamed from voteOnPoll and uses named parameters + String option
  Future<void> castVote({
    required String messId, 
    required String pollId, 
    required String selectedOption
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .update({
          'votes.${user.uid}': selectedOption
        });
  }

  // FIXED: Added named parameters
  Future<void> closePoll({required String messId, required String pollId}) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .update({'isActive': false});
  }

  Future<void> deletePoll(String messId, String pollId) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .delete();
  }
}
