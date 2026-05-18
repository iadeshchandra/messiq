import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finance/controllers/finance_provider.dart';
import '../../auth/controllers/auth_controller.dart';

// The Data Model for our AI Insight
class FundRunwayInsight {
  final double currentBalance;
  final double dailyBurnRate;
  final int daysRemaining;
  final bool isCritical;
  final String message;

  FundRunwayInsight({
    required this.currentBalance,
    required this.dailyBurnRate,
    required this.daysRemaining,
    required this.isCritical,
    required this.message,
  });
}

// The Predictive Engine
final fundRunwayProvider = Provider.family<FundRunwayInsight?, String>((ref, messId) {
  final currentUser = ref.watch(authStateProvider).value;
  final hisabList = ref.watch(individualHisabProvider(messId));
  final hisabSummary = ref.watch(hisabSummaryProvider(messId));

  if (currentUser == null || hisabList.isEmpty) return null;

  // Find the current user's specific ledger
  final myHisab = hisabList.firstWhere(
    (h) => h['member']?.uid == currentUser.uid,
    orElse: () => <String, dynamic>{},
  );

  final double balance = myHisab['balance'] ?? 0.0;
  final double mealRate = hisabSummary['mealRate'] ?? 0.0;

  // Edge case: Already in debt
  if (balance <= 0) {
     return FundRunwayInsight(
       currentBalance: balance,
       dailyBurnRate: mealRate * 2, // Assuming standard 2 meals a day
       daysRemaining: 0,
       isCritical: true,
       message: "Your balance is fully depleted. Please deposit funds immediately to maintain mess operations.",
     );
  }

  // Predictive Math: Assume 2 meals a day + a 10% buffer for shared utility/bazaar variance
  final double estimatedDailyBurn = (mealRate * 2) * 1.1;
  
  if (estimatedDailyBurn <= 0) return null; // Not enough data to predict yet

  final int days = (balance / estimatedDailyBurn).floor();
  
  // Flag as critical if the user will run out of money in 3 days or less
  final bool critical = days <= 3;

  return FundRunwayInsight(
    currentBalance: balance,
    dailyBurnRate: estimatedDailyBurn,
    daysRemaining: days,
    isCritical: critical,
    message: critical
        ? "⚠️ Warning: At your current burn rate, your balance will run out in $days day(s)."
        : "✅ You have enough advance for approximately $days days of meals.",
  );
});
