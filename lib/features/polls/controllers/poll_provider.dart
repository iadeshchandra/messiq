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

final pollControllerProvider = StateNotifierProvider<PollController, bool>((ref) {
  return PollController(ref: ref);
});

class PollController extends StateNotifier<bool> {
  final Ref ref;
  PollController({required this.ref}) : super(false); 

  Future<void> createCustomMealPoll({
    required String messId, 
    required String question, 
    required List<String> options, 
    required int deadlineHours, // UPGRADED: Smart Deadline
  }) async {
    state = true; 
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null || question.isEmpty || options.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Manager';

      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('polls').doc();
      final validOptions = options.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Calculate exact expiration time based on manager's input
      final expirationTime = DateTime.now().add(Duration(hours: deadlineHours));

      final newPoll = PollModel(
        id: docRef.id,
        question: question.trim(),
        options: validOptions,
        votes: {},
        addedByUid: user.uid,
        addedByName: userName,
        createdAt: DateTime.now(),
        isActive: true,
        expiresAt: expirationTime, 
        remindersSent: 0, // NEW: Init tracker
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, newPoll.toMap());

      final notifRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('notifications').doc();
      batch.set(notifRef, {
        'title': 'New Meal Vote 📊',
        'body': 'Closes in $deadlineHours hours! Tap to secure your meal.',
        'targetRoute': 'polls', 
        'createdAt': Timestamp.now(),
        'readBy': [],
      });

      await batch.commit();
    } finally {
      state = false; 
    }
  }

  // SMART FEATURE: Targeted Reminders Engine
  Future<void> sendSmartReminder({
    required String messId, 
    required PollModel poll
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    // 1. Increment the reminder counter in the database
    await firestore.collection('messes').doc(messId).collection('polls').doc(poll.id).update({
      'remindersSent': FieldValue.increment(1)
    });

    // 2. Fetch all active approved members in the mess
    final membersSnap = await firestore.collection('messes').doc(messId).collection('members').where('status', isEqualTo: 'approved').get();
    
    // 3. The Smart Filter: Find members who have NOT voted yet
    final List<String> unvotedUids = membersSnap.docs
        .map((doc) => doc.id)
        .where((uid) => !poll.votes.containsKey(uid)) // If they aren't in the votes map, they haven't voted!
        .toList();

    if (unvotedUids.isEmpty) return; // Everyone voted!

    // 4. Send targeted push notifications ONLY to those people
    final batch = firestore.batch();
    for (String targetUid in unvotedUids) {
      final notifRef = firestore.collection('messes').doc(messId).collection('notifications').doc();
      batch.set(notifRef, {
        'title': '⚠️ Final Call for Meals!',
        'body': 'You haven\'t voted on "${poll.question}". Please vote before the deadline!',
        'targetUid': targetUid, // Specific user only
        'targetRoute': 'polls',
        'createdAt': Timestamp.now(),
        'readBy': [],
      });
    }
    await batch.commit();
  }

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
