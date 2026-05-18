import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finance/controllers/finance_provider.dart';

class MealRateInsight {
  final double currentRate;
  final bool isHigh;
  final String title;
  final String message;
  final List<String> suggestedLowCostMeals;

  MealRateInsight({
    required this.currentRate,
    required this.isHigh,
    required this.title,
    required this.message,
    required this.suggestedLowCostMeals,
  });
}

final mealRateOptimizerProvider = Provider.family<MealRateInsight?, String>((ref, messId) {
  final summary = ref.watch(hisabSummaryProvider(messId));
  final double mealRate = summary['mealRate'] ?? 0.0;

  if (mealRate == 0.0) return null; 

  // Target thresholds for standard mess operations
  const double targetRate = 55.0;
  const double criticalRate = 70.0;

  if (mealRate >= criticalRate) {
    return MealRateInsight(
      currentRate: mealRate,
      isHigh: true,
      title: '🚨 High Meal Rate Alert',
      message: 'Your meal rate has spiked to ৳${mealRate.toStringAsFixed(1)}. To bring it down to the ৳$targetRate target, consider running a poll for these budget-friendly options tonight:',
      suggestedLowCostMeals: ['Egg Bhuna & Dal', 'Mixed Veggies (Niramish)', 'Khichuri with Alu Bhorta'],
    );
  } else if (mealRate > targetRate) {
    return MealRateInsight(
      currentRate: mealRate,
      isHigh: true,
      title: '⚠️ Meal Rate Creeping Up',
      message: 'At ৳${mealRate.toStringAsFixed(1)}, you are slightly above your target. A light dinner tonight will help balance the budget.',
      suggestedLowCostMeals: ['Lentil Soup (Dal) & Rice', 'Mashed Potatoes (Alu Bhorta)'],
    );
  } else {
    return MealRateInsight(
      currentRate: mealRate,
      isHigh: false,
      title: '✅ Budget on Track',
      message: 'Great job! Your meal rate is a healthy ৳${mealRate.toStringAsFixed(1)}. You have the budget for a premium meal (like Chicken or Fish) this weekend!',
      suggestedLowCostMeals: [],
    );
  }
});
