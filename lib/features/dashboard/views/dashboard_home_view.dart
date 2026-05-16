import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_providers.dart';
import '../../finance/controllers/finance_provider.dart';
import '../../finance/views/add_expense_screen.dart';
import '../../finance/views/add_meal_screen.dart';
import '../../finance/views/add_payment_screen.dart';
import '../../finance/views/hisab_sheet_screen.dart';
import '../../notifications/controllers/notification_provider.dart';
import '../../notifications/views/notifications_screen.dart';
import '../../bazaar/views/bazaar_list_screen.dart';
import '../../polls/views/polls_screen.dart'; // NEW IMPORT

class DashboardHomeView extends ConsumerWidget {
  final String messId;
  const DashboardHomeView({super.key, required this.messId});

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messData = ref.watch(messDetailsProvider(messId));
    final memberData = ref.watch(currentMemberRoleProvider(messId));
    final hisabSummary = ref.watch(hisabSummaryProvider(messId));
    final unreadCount = ref.watch(unreadNotificationCountProvider(messId));

    final isManager = memberData.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: messData.when(
          data: (mess) => Text(mess?.name ?? 'Dashboard', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount.toString()),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_rounded, color: AppTheme.primaryIndigo, size: 28),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(messId: messId))),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryIndigo.withOpacity(0.8), AppTheme.primaryIndigo]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.primaryIndigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
              child: Column(
                children: [
                  const Text('Current Meal Rate', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('৳${hisabSummary['mealRate'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Bazaar', '৳${hisabSummary['totalBazaar'].toStringAsFixed(0)}', Icons.shopping_basket_rounded, Colors.teal)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Total Meals', '${hisabSummary['totalMeals'].toStringAsFixed(1)}', Icons.restaurant_rounded, Colors.orange)),
              ],
            ),
            const SizedBox(height: 32),
            
            // UNIVERSAL ACCESS: Collaborative Tools
            const Text('Workspace Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            
            // Row 1: Hisab & Bazaar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HisabSheetScreen(messId: messId))),
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Hisab Sheet'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryIndigo, side: const BorderSide(color: AppTheme.primaryIndigo), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BazaarListScreen(messId: messId))),
                    icon: const Icon(Icons.checklist_rtl_rounded),
                    label: const Text('Bazaar List'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.teal, side: const BorderSide(color: Colors.teal), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Row 2: Polls
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PollsScreen(messId: messId))),
                icon: const Icon(Icons.poll_rounded),
                label: const Text('Meal Polls & Voting'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(height: 32),

            // MANAGER ONLY TOOLS
            if (isManager) ...[
              const Text('Manager Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(messId: messId))),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Hisab'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMealScreen(messId: messId))),
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                      label: const Text('Meals'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPaymentScreen(messId: messId))),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Log Member Deposit'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
