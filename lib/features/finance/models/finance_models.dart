import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String description;
  final String type; // 'Bazaar', 'Utility', 'Other'
  final DateTime date;
  final String addedByUid;

  ExpenseModel({required this.id, required this.amount, required this.description, required this.type, required this.date, required this.addedByUid});

  Map<String, dynamic> toMap() => {'id': id, 'amount': amount, 'description': description, 'type': type, 'date': Timestamp.fromDate(date), 'addedByUid': addedByUid};

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    description: map['description'] ?? '',
    type: map['type'] ?? 'Bazaar',
    date: (map['date'] as Timestamp).toDate(),
    addedByUid: map['addedByUid'] ?? '',
  );
}

class DailyMealModel {
  final String id;
  final DateTime date;
  final double totalMealsCount;
  final Map<String, double> memberMeals; 

  DailyMealModel({required this.id, required this.date, required this.totalMealsCount, required this.memberMeals});

  Map<String, dynamic> toMap() => {'id': id, 'date': Timestamp.fromDate(date), 'totalMealsCount': totalMealsCount, 'memberMeals': memberMeals};

  factory DailyMealModel.fromMap(Map<String, dynamic> map) => DailyMealModel(
    id: map['id'] ?? '',
    date: (map['date'] as Timestamp).toDate(),
    totalMealsCount: (map['totalMealsCount'] ?? 0).toDouble(),
    memberMeals: Map<String, double>.from(map['memberMeals'] ?? {}),
  );
}

// NEW: Tracks member deposits
class PaymentModel {
  final String id;
  final String memberUid;
  final double amount;
  final DateTime date;
  final String addedByUid;

  PaymentModel({required this.id, required this.memberUid, required this.amount, required this.date, required this.addedByUid});

  Map<String, dynamic> toMap() => {'id': id, 'memberUid': memberUid, 'amount': amount, 'date': Timestamp.fromDate(date), 'addedByUid': addedByUid};

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
    id: map['id'] ?? '',
    memberUid: map['memberUid'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    date: (map['date'] as Timestamp).toDate(),
    addedByUid: map['addedByUid'] ?? '',
  );
}
