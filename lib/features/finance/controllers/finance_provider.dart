import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../models/finance_models.dart';

final messExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('expenses').orderBy('date', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data())).toList());
});

final messMealsProvider = StreamProvider.family<List<DailyMealModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals').orderBy('date', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => DailyMealModel.fromMap(doc.data())).toList());
});

// NEW: Streams all member deposits
final messPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('payments').orderBy('date', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data())).toList());
});

// Auto-Calculating General Hisab (Meal Rate)
final hisabSummaryProvider = Provider.family<Map<String, dynamic>, String>((ref, messId) {
  final expenses = ref.watch(messExpensesProvider(messId)).value ?? [];
  final meals = ref.watch(messMealsProvider(messId)).value ?? [];

  double totalBazaar = 0;
  double totalUtility = 0;
  for (var expense in expenses) {
    if (expense.type == 'Bazaar') totalBazaar += expense.amount;
    else totalUtility += expense.amount;
  }

  double totalMeals = meals.fold(0.0, (sum, meal) => sum + meal.totalMealsCount);
  double mealRate = totalMeals > 0 ? totalBazaar / totalMeals : 0.0;

  return {'totalBazaar': totalBazaar, 'totalUtility': totalUtility, 'totalMeals': totalMeals, 'mealRate': mealRate};
});

// NEW: The Final Individual Hisab Calculation Matrix
final individualHisabProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, messId) {
  final members = ref.watch(messMembersDirectoryProvider(messId)).value ?? [];
  final expenses = ref.watch(messExpensesProvider(messId)).value ?? [];
  final meals = ref.watch(messMealsProvider(messId)).value ?? [];
  final payments = ref.watch(messPaymentsProvider(messId)).value ?? [];

  double totalBazaar = 0;
  double totalUtility = 0;
  for (var e in expenses) {
    if (e.type == 'Bazaar') totalBazaar += e.amount;
    else totalUtility += e.amount;
  }

  double totalMeals = 0;
  Map<String, double> memberTotalMeals = {};
  for (var meal in meals) {
    totalMeals += meal.totalMealsCount;
    meal.memberMeals.forEach((uid, count) {
      memberTotalMeals[uid] = (memberTotalMeals[uid] ?? 0) + count;
    });
  }

  double mealRate = totalMeals > 0 ? totalBazaar / totalMeals : 0.0;
  double utilityPerPerson = members.isNotEmpty ? totalUtility / members.length : 0.0;

  List<Map<String, dynamic>> hisabList = [];

  for (var member in members) {
    double myMeals = memberTotalMeals[member.uid] ?? 0.0;
    double mealCost = myMeals * mealRate;
    double totalDue = mealCost + utilityPerPerson;

    double totalPaid = payments.where((p) => p.memberUid == member.uid).fold(0.0, (sum, p) => sum + p.amount);
    
    // Positive = Mess owes them (Advance). Negative = They owe Mess (Due).
    double balance = totalPaid - totalDue; 

    hisabList.add({
      'member': member,
      'totalMeals': myMeals,
      'mealCost': mealCost,
      'utilityShare': utilityPerPerson,
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'balance': balance,
    });
  }

  return hisabList;
});

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
    } finally { state = false; }
  }

  Future<void> addDailyMeals(String messId, DateTime date, Map<String, double> memberMeals) async {
    state = true;
    try {
      double totalMeals = memberMeals.values.fold(0, (sum, count) => sum + count);
      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals').doc();
      final mealEntry = DailyMealModel(id: docRef.id, date: date, totalMealsCount: totalMeals, memberMeals: memberMeals);
      await docRef.set(mealEntry.toMap());
    } finally { state = false; }
  }

  // NEW: Save member deposit
  Future<void> addPayment(String messId, String memberUid, double amount, DateTime date) async {
    state = true;
    try {
      final uid = ref.read(authStateProvider).value!.uid;
      final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('payments').doc();
      final payment = PaymentModel(id: docRef.id, memberUid: memberUid, amount: amount, date: date, addedByUid: uid);
      await docRef.set(payment.toMap());
    } finally { state = false; }
  }
}
