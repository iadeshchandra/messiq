import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/finance_models.dart';
// NEW: Required to fetch the member list for individual Hisab calculations
import '../../dashboard/controllers/dashboard_providers.dart';

// --- DATA STREAMS ---
final messExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('expenses').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data(), doc.id)).toList());
});

final messPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('payments').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data(), doc.id)).toList());
});

final messMealsProvider = StreamProvider.family<List<DailyMealModel>, String>((ref, messId) {
  return FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals').orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => DailyMealModel.fromMap(doc.data(), doc.id)).toList());
});

// --- HISAB ENGINE CALCULATION ---
final hisabSummaryProvider = Provider.family<Map<String, dynamic>, String>((ref, messId) {
  final expenses = ref.watch(messExpensesProvider(messId)).value ?? [];
  final meals = ref.watch(messMealsProvider(messId)).value ?? [];

  double totalBazaar = expenses.where((e) => e.type.toLowerCase() == 'bazaar').fold(0.0, (sum, e) => sum + e.amount);
  double totalUtility = expenses.where((e) => e.type.toLowerCase() != 'bazaar').fold(0.0, (sum, e) => sum + e.amount);

  double totalMeals = 0.0;
  for (var meal in meals) {
    totalMeals += meal.memberMeals.values.fold(0.0, (sum, count) => sum + count);
  }

  double mealRate = totalMeals > 0 ? (totalBazaar / totalMeals) : 0.0;

  return {
    'totalBazaar': totalBazaar,
    'totalUtility': totalUtility,
    'totalMeals': totalMeals,
    'mealRate': mealRate,
  };
});

// FIXED: ADDED THE MISSING INDIVIDUAL HISAB PROVIDER
final individualHisabProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, messId) {
  final membersAsync = ref.watch(messMembersDirectoryProvider(messId));
  final paymentsAsync = ref.watch(messPaymentsProvider(messId));
  final expensesAsync = ref.watch(messExpensesProvider(messId));
  final mealsAsync = ref.watch(messMealsProvider(messId));
  final summary = ref.watch(hisabSummaryProvider(messId));

  final members = membersAsync.value ?? [];
  final payments = paymentsAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];
  final meals = mealsAsync.value ?? [];
  final mealRate = summary['mealRate'] as double;

  List<Map<String, dynamic>> memberHisabList = [];

  for (var member in members) {
    double deposits = payments.where((p) => p.memberUid == member.uid).fold(0.0, (sum, p) => sum + p.amount);
    
    double totalMeals = 0.0;
    for (var meal in meals) {
      if (meal.memberMeals.containsKey(member.uid)) {
        totalMeals += meal.memberMeals[member.uid]!;
      }
    }
    
    double mealCost = totalMeals * mealRate;
    double totalUtility = summary['totalUtility'] as double;
    double individualUtility = members.isNotEmpty ? (totalUtility / members.length) : 0.0;
    double addedExpenses = expenses.where((e) => e.addedByUid == member.uid).fold(0.0, (sum, e) => sum + e.amount);
    double totalCost = mealCost + individualUtility;
    double balance = (deposits + addedExpenses) - totalCost;

    memberHisabList.add({
      'member': member,
      'totalMeals': totalMeals,
      'mealCost': mealCost,
      'individualUtility': individualUtility,
      'totalCost': totalCost,
      'deposits': deposits,
      'addedExpenses': addedExpenses,
      'balance': balance,
    });
  }

  return memberHisabList;
});

// --- CONTROLLER ACTIONS ---
final financeControllerProvider = Provider((ref) => FinanceController(ref: ref));

class FinanceController {
  final Ref ref;
  FinanceController({required this.ref});

  Future<void> addExpense(String messId, double amount, String description, String type, DateTime date, {String? note}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Fetch current user details to stamp the record
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Manager';

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('expenses').doc();
    final expense = ExpenseModel(
      id: docRef.id,
      amount: amount,
      description: description,
      type: type,
      date: date,
      addedByUid: user.uid,
      addedByName: userName, // ACCOUNTABILITY STAMP
      note: note, // CUSTOM NOTE
    );
    await docRef.set(expense.toMap());
  }

  Future<void> addPayment(String messId, String memberUid, double amount, DateTime date, {String? note}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Manager';

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('payments').doc();
    final payment = PaymentModel(
      id: docRef.id,
      memberUid: memberUid,
      amount: amount,
      date: date,
      addedByUid: user.uid,
      addedByName: userName, // ACCOUNTABILITY STAMP
      note: note, // CUSTOM NOTE
    );
    await docRef.set(payment.toMap());
  }

  Future<void> addMeal(String messId, DateTime date, Map<String, double> memberMeals, {String? note}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Manager';

    final docRef = FirebaseFirestore.instance.collection('messes').doc(messId).collection('meals').doc();
    final meal = DailyMealModel(
      id: docRef.id,
      date: date,
      memberMeals: memberMeals,
      addedByUid: user.uid,
      addedByName: userName, // ACCOUNTABILITY STAMP
      note: note, // CUSTOM NOTE
    );
    await docRef.set(meal.toMap());
  }
}
