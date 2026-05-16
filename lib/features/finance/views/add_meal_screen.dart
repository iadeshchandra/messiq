import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../controllers/finance_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddMealScreen({super.key, required this.messId});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _mealCounts = {};

  Future<void> _submit() async {
    try {
      await ref.read(financeControllerProvider.notifier).addDailyMeals(widget.messId, _selectedDate, _mealCounts);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));
    final isLoading = ref.watch(financeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Daily Meals')),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return const Center(child: Text('No members found.'));
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final currentCount = _mealCounts[member.uid] ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1), child: Text(member.name[0])),
                          const SizedBox(width: 16),
                          Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                                onPressed: currentCount > 0 ? () => setState(() => _mealCounts[member.uid] = currentCount - 0.5) : null,
                              ),
                              Text(currentCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.teal),
                                onPressed: () => setState(() => _mealCounts[member.uid] = currentCount + 0.5),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Meals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
