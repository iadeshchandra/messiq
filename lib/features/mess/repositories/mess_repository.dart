import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messRepositoryProvider = Provider((ref) => MessRepository(firestore: FirebaseFirestore.instance));

class MessRepository {
  final FirebaseFirestore _firestore;

  MessRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<void> createMess(String name, String userId) async {
    final messId = _firestore.collection('messes').doc().id;
    final inviteCode = _generateInviteCode();

    final batch = _firestore.batch();
    
    batch.set(_firestore.collection('messes').doc(messId), {
      'id': messId, 'name': name, 'inviteCode': inviteCode, 'managerId': userId, 'createdAt': Timestamp.now(),
    });
    
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), {
      'uid': userId, 'role': 'manager', 'status': 'approved', 'joinedAt': Timestamp.now(),
    });
    
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': messId}, SetOptions(merge: true));
    
    await batch.commit();
  }

  Future<void> joinMess(String inviteCode, String userId) async {
    final query = await _firestore.collection('messes').where('inviteCode', isEqualTo: inviteCode).limit(1).get();
    if (query.docs.isEmpty) throw Exception('Invalid invite code. Please check and try again.');

    final messId = query.docs.first.id;
    
    // Fetch user name so the notification is personalized
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Someone';

    final batch = _firestore.batch();
    
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), {
      'uid': userId, 'role': 'member', 'status': 'pending', 'joinedAt': Timestamp.now(),
    });
    
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': messId}, SetOptions(merge: true));
    
    // AUTO-TRIGGER NOTIFICATION TO MANAGER
    final notifRef = _firestore.collection('messes').doc(messId).collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'New Join Request 🚪',
      'body': '$userName wants to join the mess. Go to Members to approve them.',
      'targetRole': 'manager',
      'createdAt': Timestamp.now(),
      'readBy': [],
    });

    await batch.commit();
  }

  Future<void> approveMember(String messId, String userId) async {
    final batch = _firestore.batch();
    
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), {
      'status': 'approved'
    }, SetOptions(merge: true));
    
    // AUTO-TRIGGER NOTIFICATION TO THE MEMBER WHO GOT APPROVED
    final notifRef = _firestore.collection('messes').doc(messId).collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'Welcome to the Mess! 🎉',
      'body': 'Your join request was approved by the manager. You now have full access.',
      'targetUid': userId,
      'createdAt': Timestamp.now(),
      'readBy': [],
    });

    await batch.commit();
  }

  Future<void> removeOrRejectMember(String messId, String userId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('messes').doc(messId).collection('members').doc(userId));
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': FieldValue.delete()}, SetOptions(merge: true));
    await batch.commit();
  }
}
