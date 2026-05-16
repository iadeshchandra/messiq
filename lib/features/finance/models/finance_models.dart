import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String description;
  final String type; // e.g., 'Bazaar', 'Utility', 'Other'
  final DateTime date;
  final String addedByUid;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    required this.addedByUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type,
      'date': Timestamp.fromDate(date),
      'addedByUid': addedByUid,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      type: map['type'] ?? 'Bazaar',
      date: (map['date'] as Timestamp).toDate(),
      addedByUid: map['addedByUid'] ?? '',
    );
  }
}

class DailyMealModel {
  final String id;
  final DateTime date;
  final double totalMealsCount;
  final Map<String, double> memberMeals; // UID -> Meal Count (e.g., 1.5, 2.0)

  DailyMealModel({
    required this.id,
    required this.date,
    required this.totalMealsCount,
    required this.memberMeals,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'totalMealsCount': totalMealsCount,
      'memberMeals': memberMeals,
    };
  }

  factory DailyMealModel.fromMap(Map<String, dynamic> map) {
    return DailyMealModel(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      totalMealsCount: (map['totalMealsCount'] ?? 0).toDouble(),
      memberMeals: Map<String, double>.from(map['memberMeals'] ?? {}),
    );
  }
}
