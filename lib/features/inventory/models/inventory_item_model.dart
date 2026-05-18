import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String name;
  final double currentQuantity;
  final double initialQuantity;
  final String unit;
  final double estimatedDailyBurn; // AI predicts how much is eaten per day
  final bool alertTriggered; // Prevents the AI from spamming the Bazaar list
  final DateTime lastUpdated;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.currentQuantity,
    required this.initialQuantity,
    required this.unit,
    required this.estimatedDailyBurn,
    this.alertTriggered = false,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentQuantity': currentQuantity,
      'initialQuantity': initialQuantity,
      'unit': unit,
      'estimatedDailyBurn': estimatedDailyBurn,
      'alertTriggered': alertTriggered,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryItemModel(
      id: docId,
      name: map['name'] ?? 'Unknown Item',
      currentQuantity: (map['currentQuantity'] ?? 0.0).toDouble(),
      initialQuantity: (map['initialQuantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      estimatedDailyBurn: (map['estimatedDailyBurn'] ?? 0.0).toDouble(),
      alertTriggered: map['alertTriggered'] ?? false,
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  // AI Logic: Calculates exactly how many days of food are left
  int get daysRemaining {
    if (estimatedDailyBurn <= 0) return 99; // Infinite
    return (currentQuantity / estimatedDailyBurn).floor();
  }

  // AI Logic: Determines if the stock is in the danger zone
  bool get isCritical => daysRemaining <= 2;
}
