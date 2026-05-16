import 'package:cloud_firestore/cloud_firestore.dart';

class DutyModel {
  final String id;
  final String title; 
  final String assignedToUid;
  final String assignedToName;
  final DateTime assignedDate;
  final DateTime? dueTime; // NEW: Precise deadline
  final bool isCompleted;
  final String addedByUid;
  final DateTime createdAt;

  DutyModel({
    required this.id,
    required this.title,
    required this.assignedToUid,
    required this.assignedToName,
    required this.assignedDate,
    this.dueTime,
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
      if (dueTime != null) 'dueTime': Timestamp.fromDate(dueTime!),
      'isCompleted': isCompleted,
      'addedByUid': addedByUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DutyModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedAssignedDate = DateTime.now();
    if (map['assignedDate'] != null) {
      if (map['assignedDate'] is Timestamp) {
        parsedAssignedDate = (map['assignedDate'] as Timestamp).toDate();
      } else if (map['assignedDate'] is String) {
        parsedAssignedDate = DateTime.tryParse(map['assignedDate']) ?? DateTime.now();
      }
    }

    DateTime? parsedDueTime;
    if (map['dueTime'] != null) {
      if (map['dueTime'] is Timestamp) {
        parsedDueTime = (map['dueTime'] as Timestamp).toDate();
      } else if (map['dueTime'] is String) {
        parsedDueTime = DateTime.tryParse(map['dueTime']);
      }
    }

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
      dueTime: parsedDueTime,
      isCompleted: map['isCompleted'] ?? false,
      addedByUid: map['addedByUid']?.toString() ?? '',
      createdAt: parsedCreatedAt,
    );
  }
}
