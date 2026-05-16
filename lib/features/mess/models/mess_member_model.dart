import 'package:cloud_firestore/cloud_firestore.dart';

class MessMemberModel {
  final String uid;
  final String role; 
  final String status; 
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
    // CRITICAL FIX: Indestructible Date Parsing
    DateTime parsedJoinedAt = DateTime.now();
    if (map['joinedAt'] != null) {
      if (map['joinedAt'] is String) {
        parsedJoinedAt = DateTime.tryParse(map['joinedAt']) ?? DateTime.now();
      } else if (map['joinedAt'] is Timestamp) {
        parsedJoinedAt = (map['joinedAt'] as Timestamp).toDate();
      }
    }

    return MessMemberModel(
      uid: map['uid']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'approved',
      joinedAt: parsedJoinedAt,
    );
  }
}
