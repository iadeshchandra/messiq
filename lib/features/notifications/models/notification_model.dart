import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? targetRole; // e.g., 'manager' (null means it's for everyone or a specific UID)
  final String? targetUid;  // e.g., 'user123' (null means it's for a role or everyone)
  final DateTime createdAt;
  final List<String> readBy; // List of UIDs who have seen this

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.targetRole,
    this.targetUid,
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
      createdAt: parsedDate,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
