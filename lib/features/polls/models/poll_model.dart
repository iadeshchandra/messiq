import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // Maps a User's UID to the Index of the option they voted for
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;
  final bool isActive;

  PollModel({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.addedByUid,
    required this.addedByName,
    required this.createdAt,
    this.isActive = true,
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

    return PollModel(
      id: docId,
      question: map['question']?.toString() ?? 'Untitled Poll',
      options: List<String>.from(map['options'] ?? []),
      votes: Map<String, int>.from(map['votes'] ?? {}),
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Member',
      createdAt: parsedDate,
      isActive: map['isActive'] ?? true,
    );
  }
}
