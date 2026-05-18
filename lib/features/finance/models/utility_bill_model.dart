import 'package:cloud_firestore/cloud_firestore.dart';

class UtilityBillModel {
  final String id;
  final String title;
  final String type; // 'WiFi', 'Electricity', 'Gas', 'Maid/Khala', 'Other'
  final double totalAmount;
  final double perMemberShare;
  final String addedByUid;
  final String addedByName;
  final DateTime date;
  final List<String> splitBetweenUids;

  UtilityBillModel({
    required this.id,
    required this.title,
    required this.type,
    required this.totalAmount,
    required this.perMemberShare,
    required this.addedByUid,
    required this.addedByName,
    required this.date,
    required this.splitBetweenUids,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'totalAmount': totalAmount,
      'perMemberShare': perMemberShare,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'date': Timestamp.fromDate(date),
      'splitBetweenUids': splitBetweenUids,
    };
  }

  factory UtilityBillModel.fromMap(Map<String, dynamic> map) {
    return UtilityBillModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'Other',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      perMemberShare: (map['perMemberShare'] ?? 0.0).toDouble(),
      addedByUid: map['addedByUid'] ?? '',
      addedByName: map['addedByName'] ?? 'Manager',
      date: (map['date'] as Timestamp).toDate(),
      splitBetweenUids: List<String>.from(map['splitBetweenUids'] ?? []),
    );
  }
}
