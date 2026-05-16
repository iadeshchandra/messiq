import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../finance/controllers/finance_provider.dart';

class MemberLedgerScreen extends ConsumerStatefulWidget {
  final UserModel member;
  final String messId;

  const MemberLedgerScreen({super.key, required this.member, required this.messId});

  @override
  ConsumerState<MemberLedgerScreen> createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends ConsumerState<MemberLedgerScreen> {
  DateTimeRange? _selectedRange;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryIndigo,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedRange = null);
  }

  bool _isWithinRange(DateTime date) {
    if (_selectedRange == null) return true;
    // Add 1 day to the end date to include the full final day
    return date.isAfter(_selectedRange!.start.subtract(const Duration(seconds: 1))) && 
           date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(messPaymentsProvider(widget.messId));
    final mealsAsync = ref.watch(messMealsProvider(widget.messId));
    final expensesAsync = ref.watch(messExpensesProvider(widget.messId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('${widget.member.name.split(' ')[0]}\'s Ledger', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          actions: [
            // PDF Button Placeholder (We will build this in the next step!)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryIndigo),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming in the next step!')));
              },
            )
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryIndigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryIndigo,
            tabs: [
              Tab(text: 'Deposits', icon: Icon(Icons.payments_rounded)),
              Tab(text: 'Meals', icon: Icon(Icons.restaurant_rounded)),
              Tab(text: 'Added Expenses', icon: Icon(Icons.shopping_cart_rounded)),
            ],
          ),
        ),
        body: Column(
          children: [
            // DATE FILTER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedRange == null 
                          ? 'Showing All History' 
                          : '${_selectedRange!.start.toString().split(' ')[0]} to ${_selectedRange!.end.toString().split(' ')[0]}',
                      style: TextStyle(fontWeight: _selectedRange == null ? FontWeight.normal : FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                  if (_selectedRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.redAccent),
                      onPressed: _clearDateFilter,
                      tooltip: 'Clear Filter',
                    ),
                  TextButton(
                    onPressed: _pickDateRange,
                    child: const Text('Filter Date', style: TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            
            // TABS CONTENT
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: DEPOSITS
                  paymentsAsync.when(
                    data: (payments) {
                      final filtered = payments.where((p) => p.memberUid == widget.member.uid && _isWithinRange(p.date)).toList();
                      if (filtered.isEmpty) return const Center(child: Text('No deposits found in this timeframe.'));
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.add, color: Colors.white)),
                            title: Text('Deposit', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(filtered[i].date.toString().split(' ')[0]),
                            trailing: Text('৳${filtered[i].amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  // TAB 2: MEALS
                  mealsAsync.when(
                    data: (meals) {
                      final filtered = meals.where((m) => m.memberMeals.containsKey(widget.member.uid) && m.memberMeals[widget.member.uid]! > 0 && _isWithinRange(m.date)).toList();
                      if (filtered.isEmpty) return const Center(child: Text('No meals found in this timeframe.'));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final count = filtered[i].memberMeals[widget.member.uid]!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.restaurant, color: Colors.orange)),
                              title: Text('${count.toStringAsFixed(1)} Meals Logged', style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Text(filtered[i].date.toString().split(' ')[0], style: const TextStyle(color: Colors.grey)),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),

                  // TAB 3: EXPENSES ADDED
                  expensesAsync.when(
                    data: (expenses) {
                      // Filter by addedByUid to see what this user purchased for the mess
                      final filtered = expenses.where((e) => e.addedByUid == widget.member.uid && _isWithinRange(e.date)).toList();
                      if (filtered.isEmpty) return const Center(child: Text('No expenses added by this member.'));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.2), child: const Icon(Icons.shopping_basket, color: Colors.teal)),
                            title: Text(filtered[i].description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${filtered[i].type} • ${filtered[i].date.toString().split(' ')[0]}'),
                            trailing: Text('৳${filtered[i].amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
