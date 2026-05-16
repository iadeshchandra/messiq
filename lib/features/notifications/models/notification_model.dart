import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? targetRole; // e.g., 'manager'
  final String? targetUid;  // e.g., 'user123'
  final String? targetRoute; // NEW: The screen to open (e.g., 'duties', 'polls', 'profile')
  final String? referenceId; // NEW: The specific item ID if needed
  final DateTime createdAt;
  final List<String> readBy; 

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.targetRole,
    this.targetUid,
    this.targetRoute,
    this.referenceId,
    required this.createdAt,
    required this.readBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'targetRole': targetRole,
      'targetUid': targetUid,
      'targetRoute': targetRoute,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return NotificationModel(
      id: docId,
      title: map['title']?.toString() ?? 'Notification',
      body: map['body']?.toString() ?? '',
      targetRole: map['targetRole']?.toString(),
      targetUid: map['targetUid']?.toString(),
      targetRoute: map['targetRoute']?.toString(),
      referenceId: map['referenceId']?.toString(),
      createdAt: parsedDate,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
