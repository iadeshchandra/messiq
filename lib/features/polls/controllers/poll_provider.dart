import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/poll_model.dart';

// Stream all polls for this mess, ordered by newest first
final messPollsProvider = StreamProvider.family<List<PollModel>, String>((ref, messId) {
  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('polls')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PollModel.fromMap(doc.data(), doc.id)).toList());
});

final pollControllerProvider = Provider((ref) => PollController(ref: ref));

class PollController {
  final Ref ref;
  PollController({required this.ref});

  // Create a new poll and alert the whole mess
  Future<void> createPoll(String messId, String question, List<String> options) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || question.isEmpty || options.isEmpty) return;

    // Fetch the creator's name
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Member';

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('polls').doc();

    // Clean up empty options
    final validOptions = options.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final newPoll = PollModel(
      id: docRef.id,
      question: question.trim(),
      options: validOptions,
      votes: {}, // Empty map to start
      addedByUid: user.uid,
      addedByName: userName,
      createdAt: DateTime.now(),
      isActive: true,
    );

    final batch = FirebaseFirestore.instance.batch();
    batch.set(docRef, newPoll.toMap());

    // AUTO-TRIGGER NOTIFICATION TO EVERYONE
    final notifRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'New Poll Created 📊',
      'body': '$userName asked: "$question". Tap to cast your vote!',
      'createdAt': Timestamp.now(),
      'readBy': [], // Empty means unread by everyone
    });

    await batch.commit();
  }

  // Cast or change a vote
  Future<void> voteOnPoll(String messId, String pollId, int optionIndex) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // We use dot notation to update just this user's vote inside the map
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .update({
          'votes.${user.uid}': optionIndex
        });
  }

  // Lock the poll so no more votes can be cast
  Future<void> closePoll(String messId, String pollId) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .update({'isActive': false});
  }

  // Completely delete the poll
  Future<void> deletePoll(String messId, String pollId) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('polls')
        .doc(pollId)
        .delete();
  }
}
