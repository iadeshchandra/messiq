import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String description;
  final String type; // e.g., 'bazaar', 'utility'
  final DateTime date;
  final String addedByUid;
  // NEW: Accountability Fields
  final String addedByName; 
  final String? note; 

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    required this.addedByUid,
    this.addedByName = 'Manager',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'description': description,
    'type': type,
    'date': Timestamp.fromDate(date),
    'addedByUid': addedByUid,
    'addedByName': addedByName,
    'note': note,
  };

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseModel(
      id: docId,
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? 'bazaar',
      date: (map['date'] as Timestamp).toDate(),
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Manager',
      note: map['note']?.toString(),
    );
  }
}

class PaymentModel {
  final String id;
  final String memberUid;
  final double amount;
  final DateTime date;
  // NEW: Accountability Fields
  final String addedByUid; 
  final String addedByName; 
  final String? note; 

  PaymentModel({
    required this.id,
    required this.memberUid,
    required this.amount,
    required this.date,
    this.addedByUid = '',
    this.addedByName = 'Manager',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'memberUid': memberUid,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'addedByUid': addedByUid,
    'addedByName': addedByName,
    'note': note,
  };

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentModel(
      id: docId,
      memberUid: map['memberUid']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Manager',
      note: map['note']?.toString(),
    );
  }
}

class DailyMealModel {
  final String id;
  final DateTime date;
  final Map<String, double> memberMeals;
  // NEW: Accountability Fields
  final String addedByUid; 
  final String addedByName; 
  final String? note; 

  DailyMealModel({
    required this.id,
    required this.date,
    required this.memberMeals,
    this.addedByUid = '',
    this.addedByName = 'Manager',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': Timestamp.fromDate(date),
    'memberMeals': memberMeals,
    'addedByUid': addedByUid,
    'addedByName': addedByName,
    'note': note,
  };

  factory DailyMealModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawMeals = map['memberMeals'] as Map<String, dynamic>? ?? {};
    final parsedMeals = rawMeals.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return DailyMealModel(
      id: docId,
      date: (map['date'] as Timestamp).toDate(),
      memberMeals: parsedMeals,
      addedByUid: map['addedByUid']?.toString() ?? '',
      addedByName: map['addedByName']?.toString() ?? 'Manager',
      note: map['note']?.toString(),
    );
  }
}
