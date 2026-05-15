import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mess_model.dart';
import '../models/mess_member_model.dart';

final messRepositoryProvider = Provider((ref) => MessRepository(
      firestore: FirebaseFirestore.instance,
    ));

class MessRepository {
  final FirebaseFirestore _firestore;

  MessRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Generate a random 6-digit alphanumeric code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<void> createMess(String name, String userId) async {
    final messId = _firestore.collection('messes').doc().id;
    final inviteCode = _generateInviteCode();

    final mess = MessModel(
      id: messId,
      name: name,
      inviteCode: inviteCode,
      managerId: userId,
      createdAt: DateTime.now(),
    );

    final member = MessMemberModel(
      uid: userId,
      role: 'manager',
      status: 'approved',
      joinedAt: DateTime.now(),
    );

    // Batch write to ensure both mess and member are created simultaneously
    final batch = _firestore.batch();
    batch.set(_firestore.collection('messes').doc(messId), mess.toMap());
    batch.set(_firestore.collection('messes').doc(messId).collection('members').doc(userId), member.toMap());
    await batch.commit();
  }

  Future<void> joinMess(String inviteCode, String userId) async {
    // 1. Find the mess by invite code
    final query = await _firestore.collection('messes').where('inviteCode', isEqualTo: inviteCode).limit(1).get();
    
    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code');
    }

    final messId = query.docs.first.id;

    // 2. Create a pending member request
    final member = MessMemberModel(
      uid: userId,
      role: 'member',
      status: 'pending',
      joinedAt: DateTime.now(),
    );

    await _firestore.collection('messes').doc(messId).collection('members').doc(userId).set(member.toMap());
  }
}
