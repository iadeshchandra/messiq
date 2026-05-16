import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/finance_models.dart';

// 1. Stream all expenses for the mess
final messExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('expenses')
      .orderBy('date', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data())).toList());
});

// 2. Stream all meals for the mess
final messMealsProvider = StreamProvider.family<List<DailyMealModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals')
      .orderBy('date', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => DailyMealModel.fromMap(doc.data())).toList());
});

// 3. The Auto-Calculating Hisab Engine
final hisabSummaryProvider = Provider.family<Map<String, dynamic>, String>((ref, messId) {
  final expenses = ref.watch(messExpensesProvider(messId)).value ?? [];
  final meals = ref.watch(messMealsProvider(messId)).value ?? [];

  double totalBazaar = 0;
  double totalUtility = 0;
  for (var expense in expenses) {
    if (expense.type == 'Bazaar') {
      totalBazaar += expense.amount;
    } else {
      totalUtility += expense.amount;
    }
  }

  double totalMeals = 0;
  for (var meal in meals) {
    totalMeals += meal.totalMealsCount;
  }

  // Live Meal Rate Formula: Total Bazaar / Total Meals
  double mealRate = totalMeals > 0 ? totalBazaar / totalMeals : 0.0;

  return {
    'totalBazaar': totalBazaar,
    'totalUtility': totalUtility,
    'totalMeals': totalMeals,
    'mealRate': mealRate,
  };
});

// 4. Controller to write data to Firebase
final financeControllerProvider = StateNotifierProvider<FinanceController, bool>((ref) => FinanceController(ref));

class FinanceController extends StateNotifier<bool> {
  final Ref ref;
  FinanceController(this.ref) : super(false);

  Future<void> addExpense(String messId, double amount, String description, String type, DateTime date) async {
    state = true;
    try {
      final uid = ref.read(authStateProvider).value!.uid;
      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('expenses').doc();
      final expense = ExpenseModel(id: docRef.id, amount: amount, description: description, type: type, date: date, addedByUid: uid);
      await docRef.set(expense.toMap());
    } finally {
      state = false;
    }
  }

  Future<void> addDailyMeals(String messId, DateTime date, Map<String, double> memberMeals) async {
    state = true;
    try {
      double totalMeals = memberMeals.values.fold(0, (sum, count) => sum + count);
      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals').doc();
      final mealEntry = DailyMealModel(id: docRef.id, date: date, totalMealsCount: totalMeals, memberMeals: memberMeals);
      await docRef.set(mealEntry.toMap());
    } finally {
      state = false;
    }
  }
}
