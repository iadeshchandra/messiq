import 'package:cloud_firestore/cloud_firestore.dart';

class BazaarItemModel {
  final String id;
  final String name;
  final double quantity;
  final String unit; // 'kg', 'litre', 'piece', etc.
  final bool isBought;
  final String addedByName;
  final String? boughtByName;
  final double estimatedCost;
  final DateTime createdAt;

  BazaarItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isBought,
    required this.addedByName,
    this.boughtByName,
    required this.estimatedCost,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isBought': isBought,
      'addedByName': addedByName,
      'boughtByName': boughtByName,
      'estimatedCost': estimatedCost,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BazaarItemModel.fromMap(Map<String, dynamic> map) {
    return BazaarItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      isBought: map['isBought'] ?? false,
      addedByName: map['addedByName'] ?? 'Anonymous',
      boughtByName: map['boughtByName'],
      estimatedCost: (map['estimatedCost'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
