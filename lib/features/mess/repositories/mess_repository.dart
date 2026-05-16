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
      'id': messId, 
      'name': name, 
      'inviteCode': inviteCode, 
      'managerId': userId, 
      'createdAt': Timestamp.now(),
    });
    
    // Creator is instantly approved
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), {
      'uid': userId, 
      'role': 'manager', 
      'status': 'approved', 
      'joinedAt': Timestamp.now(),
    });
    
    // THE FIX: Set with merge prevents 'not-found' crashes completely
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': messId}, SetOptions(merge: true));
    
    await batch.commit();
  }

  Future<void> joinMess(String inviteCode, String userId) async {
    // Check if the invite code actually exists
    final query = await _firestore.collection('messes').where('inviteCode', isEqualTo: inviteCode).limit(1).get();
    if (query.docs.isEmpty) throw Exception('Invalid invite code. Please check and try again.');

    final messId = query.docs.first.id;

    final batch = _firestore.batch();
    
    // Add to waiting room (pending)
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), {
      'uid': userId, 
      'role': 'member', 
      'status': 'pending', 
      'joinedAt': Timestamp.now(),
    });
    
    // THE FIX: Set with merge prevents 'not-found' crashes completely
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': messId}, SetOptions(merge: true));
    
    await batch.commit();
  }

  // MANAGER TOOL: Approve a waiting user
  Future<void> approveMember(String messId, String userId) async {
    await _firestore.collection('messes').doc(messId).collection('members').doc(userId).set({
      'status': 'approved'
    }, SetOptions(merge: true));
  }

  // MANAGER / USER TOOL: Reject or Cancel a request
  Future<void> removeOrRejectMember(String messId, String userId) async {
    final batch = _firestore.batch();
    
    // Remove from mess members list
    batch.delete(_firestore.collection('messes').doc(messId).collection('members').doc(userId));
    
    // THE FIX: Safely remove the messId from their profile without crashing if they don't exist
    batch.set(_firestore.collection('users').doc(userId), {'activeMessId': FieldValue.delete()}, SetOptions(merge: true));
    
    await batch.commit();
  }
}
