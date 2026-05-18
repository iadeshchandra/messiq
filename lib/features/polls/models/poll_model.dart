import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, dynamic> votes; // UPGRADED: Set to dynamic to handle String options from the UI
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? expiresAt; 
  final int remindersSent; // NEW: Smart Reminder feature tracker

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
    this.remindersSent = 0, // NEW: Defaults to 0 when poll is created
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
      'remindersSent': remindersSent, // NEW: Saves to DB
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
      votes: Map<String, dynamic>.from(map['votes'] ?? {}), // UPGRADED
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Member',
      createdAt: parsedDate,
      isActive: map['isActive'] ?? true,
      expiresAt: parsedExpires,
      remindersSent: map['remindersSent'] ?? 0, // NEW: Parses from DB
    );
  }
}
