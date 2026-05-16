import 'package:cloud_firestore/cloud_firestore.dart';

class BazaarItemModel {
  final String id;
  final String name;
  final bool isPurchased;
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;

  BazaarItemModel({
    required this.id,
    required this.name,
    this.isPurchased = false,
    required this.addedByUid,
    required this.addedByName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isPurchased': isPurchased,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BazaarItemModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return BazaarItemModel(
      id: docId,
      name: map['name']?.toString() ?? 'Unknown Item',
      isPurchased: map['isPurchased'] ?? false,
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Someone',
      createdAt: parsedDate,
    );
  }
}
