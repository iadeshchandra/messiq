import 'package:cloud_firestore/cloud_firestore.dart';

class MessMemberModel {
  final String uid;
  final String role; // 'manager' or 'member'
  final String status; // 'approved' or 'pending'
  final DateTime joinedAt;

  MessMemberModel({
    required this.uid,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory MessMemberModel.fromMap(Map<String, dynamic> map) {
    return MessMemberModel(
      uid: map['uid'] ?? '',
      role: map['role'] ?? 'member',
      // Default to approved if older users don't have the status field yet
      status: map['status'] ?? 'approved', 
      joinedAt: map['joinedAt'] != null 
          ? (map['joinedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
