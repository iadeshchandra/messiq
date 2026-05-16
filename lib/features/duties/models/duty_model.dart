import 'package:cloud_firestore/cloud_firestore.dart';

class DutyModel {
  final String id;
  final String title; // e.g., "Bazaar Duty", "Room Cleaning"
  final String assignedToUid;
  final String assignedToName;
  final DateTime assignedDate;
  final bool isCompleted;
  final String addedByUid;
  final DateTime createdAt;

  DutyModel({
    required this.id,
    required this.title,
    required this.assignedToUid,
    required this.assignedToName,
    required this.assignedDate,
    this.isCompleted = false,
    required this.addedByUid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'isCompleted': isCompleted,
      'addedByUid': addedByUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DutyModel.fromMap(Map<String, dynamic> map, String docId) {
    // Indestructible Assigned Date Parsing
    DateTime parsedAssignedDate = DateTime.now();
    if (map['assignedDate'] != null) {
      if (map['assignedDate'] is Timestamp) {
        parsedAssignedDate = (map['assignedDate'] as Timestamp).toDate();
      } else if (map['assignedDate'] is String) {
        parsedAssignedDate = DateTime.tryParse(map['assignedDate']) ?? DateTime.now();
      }
    }

    // Indestructible Created At Parsing
    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return DutyModel(
      id: docId,
      title: map['title']?.toString() ?? 'Unknown Duty',
      assignedToUid: map['assignedToUid']?.toString() ?? '',
      assignedToName: map['assignedToName']?.toString() ?? 'Member',
      assignedDate: parsedAssignedDate,
      isCompleted: map['isCompleted'] ?? false,
      addedByUid: map['addedByUid']?.toString() ?? '',
      createdAt: parsedCreatedAt,
    );
  }
}
