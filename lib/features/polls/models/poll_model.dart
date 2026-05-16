import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? expiresAt; // NEW: Deadline feature

  PollModel({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.addedByUid,
    required this.addedByName,
    required this.createdAt,
    this.isActive = true,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'votes': votes,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  factory PollModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    DateTime? parsedExpires;
    if (map['expiresAt'] != null) {
      if (map['expiresAt'] is Timestamp) {
        parsedExpires = (map['expiresAt'] as Timestamp).toDate();
      } else if (map['expiresAt'] is String) {
        parsedExpires = DateTime.tryParse(map['expiresAt']);
      }
    }

    return PollModel(
      id: docId,
      question: map['question']?.toString() ?? 'Untitled Poll',
      options: List<String>.from(map['options'] ?? []),
      votes: Map<String, int>.from(map['votes'] ?? {}),
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Member',
      createdAt: parsedDate,
      isActive: map['isActive'] ?? true,
      expiresAt: parsedExpires,
    );
  }
}
