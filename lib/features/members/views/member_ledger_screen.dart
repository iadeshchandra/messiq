import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../finance/controllers/finance_provider.dart';
import '../../finance/services/pdf_service.dart';
import '../../dashboard/controllers/dashboard_providers.dart';

class MemberLedgerScreen extends ConsumerStatefulWidget {
  final UserModel member;
  final String messId;

  const MemberLedgerScreen({super.key, required this.member, required this.messId});

  @override
  ConsumerState<MemberLedgerScreen> createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends ConsumerState<MemberLedgerScreen> {
  DateTimeRange? _selectedRange;
  bool _isExporting = false;

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
    return date.isAfter(_selectedRange!.start.subtract(const Duration(seconds: 1))) && 
           date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
  }

  Future<void> _exportLedgerPdf(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final messData = await ref.read(messDetailsProvider(widget.messId).future);
      if (messData == null) throw Exception("Mess data not found.");

      final allPayments = ref.read(messPaymentsProvider(widget.messId)).value ?? [];
      final allMeals = ref.read(messMealsProvider(widget.messId)).value ?? [];
      final allExpenses = ref.read(messExpensesProvider(widget.messId)).value ?? [];

      final filteredPayments = allPayments.where((p) => p.memberUid == widget.member.uid && _isWithinRange(p.date)).toList();
      final filteredMeals = allMeals.where((m) => m.memberMeals.containsKey(widget.member.uid) && m.memberMeals[widget.member.uid]! > 0 && _isWithinRange(m.date)).toList();
      final filteredExpenses = allExpenses.where((e) => e.addedByUid == widget.member.uid && _isWithinRange(e.date)).toList();

      String dateRangeText = _selectedRange == null 
          ? 'All History' 
          : '${_selectedRange!.start.toString().split(' ')[0]} to ${_selectedRange!.end.toString().split(' ')[0]}';

      final File pdfFile = await PdfService.generateMemberLedgerPdf(
        messName: messData.name,
        member: widget.member,
        dateRangeText: dateRangeText,
        deposits: filteredPayments,
        meals: filteredMeals,
        expenses: filteredExpenses,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportSuccessSheet(context, pdfFile);
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showExportSuccessSheet(BuildContext context, File pdfFile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Ledger PDF Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('Activity report for ${widget.member.name} has been generated successfully.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download to Device'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  try {
                    final downloadDir = Directory('/storage/emulated/0/Download');
                    if (await downloadDir.exists()) {
                      final newPath = '${downloadDir.path}/${pdfFile.path.split('/').last}';
                      await pdfFile.copy(newPath);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully to Downloads!'), backgroundColor: Colors.green));
                      }
                    } else {
                      throw Exception("Downloads folder not found.");
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download: Try using Share to save.'), backgroundColor: Colors.orange));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Report'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryIndigo, side: const BorderSide(color: AppTheme.primaryIndigo), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Share.shareXFiles([XFile(pdfFile.path)], text: 'MessIQ Activity Ledger for ${widget.member.name}');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
            if (_isExporting)
              const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryIndigo),
                onPressed: () => _exportLedgerPdf(context),
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
                        itemBuilder: (ctx, i) {
                          final payment = filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.add, color: Colors.white)),
                              title: const Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${payment.date.toString().split(' ')[0]} • Logged by ${payment.addedByName}'),
                                  if (payment.note != null && payment.note!.isNotEmpty)
                                    Text('Note: ${payment.note}', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: Text('৳${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              isThreeLine: payment.note != null && payment.note!.isNotEmpty,
                            ),
                          );
                        },
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
                          final meal = filtered[i];
                          final count = meal.memberMeals[widget.member.uid]!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.restaurant, color: Colors.orange)),
                              title: Text('${count.toStringAsFixed(1)} Meals Logged', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Logged by ${meal.addedByName}'),
                                  if (meal.note != null && meal.note!.isNotEmpty)
                                    Text('Note: ${meal.note}', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: Text(meal.date.toString().split(' ')[0], style: const TextStyle(color: Colors.grey)),
                              isThreeLine: meal.note != null && meal.note!.isNotEmpty,
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
                      final filtered = expenses.where((e) => e.addedByUid == widget.member.uid && _isWithinRange(e.date)).toList();
                      if (filtered.isEmpty) return const Center(child: Text('No expenses added by this member.'));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final expense = filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.2), child: const Icon(Icons.shopping_basket, color: Colors.teal)),
                              title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${expense.type} • ${expense.date.toString().split(' ')[0]}'),
                                  if (expense.note != null && expense.note!.isNotEmpty)
                                    Text('Note: ${expense.note}', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: Text('৳${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                              isThreeLine: expense.note != null && expense.note!.isNotEmpty,
                            ),
                          );
                        },
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
