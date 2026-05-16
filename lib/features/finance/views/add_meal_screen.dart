import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/finance_provider.dart';
import '../../dashboard/controllers/dashboard_providers.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final String messId;
  const AddMealScreen({super.key, required this.messId});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final Map<String, double> _memberMeals = {};
  final _noteCtrl = TextEditingController(); 
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Log Daily Meals', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppTheme.backgroundLight, elevation: 0),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) return const Center(child: Text('No members found.'));

          // Initialize default meal counts to 0 if not set
          for (var m in members) {
            _memberMeals.putIfAbsent(m.uid, () => 0.0);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text('Meal Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: Colors.white,
                      leading: const Icon(Icons.calendar_today, color: AppTheme.primaryIndigo),
                      title: Text(_date.toString().split(' ')[0]),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text('Manager Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'e.g., Friday special meal', 
                        filled: true, 
                        fillColor: Colors.white, 
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.orange), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Member Meal Counts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...members.map((m) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: AppTheme.primaryIndigo.withOpacity(0.1), child: Text(m.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 16),
                              Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      if (_memberMeals[m.uid]! >= 0.5) {
                                        setState(() => _memberMeals[m.uid] = _memberMeals[m.uid]! - 0.5);
                                      }
                                    },
                                  ),
                                  Text(_memberMeals[m.uid]!.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => setState(() => _memberMeals[m.uid] = _memberMeals[m.uid]! + 0.5),
                                  ),
                                  // NEW: THE SPONSORED GUEST BUTTON
                                  Container(
                                    height: 32,
                                    width: 1,
                                    color: Colors.grey.shade300,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.orange),
                                    tooltip: 'Add Guest Meal for ${m.name.split(' ')[0]}',
                                    onPressed: () {
                                      setState(() {
                                        // 1. Add a full meal to the sponsor
                                        _memberMeals[m.uid] = _memberMeals[m.uid]! + 1.0; 
                                        
                                        // 2. Automatically generate the accountability note
                                        String currentNote = _noteCtrl.text;
                                        String addition = '+1 Guest for ${m.name.split(' ')[0]}';
                                        _noteCtrl.text = currentNote.isEmpty ? addition : '$currentNote, $addition';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guest meal assigned to ${m.name.split(' ')[0]}'), duration: const Duration(seconds: 1)));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ref.read(financeControllerProvider).addMeal(
                          widget.messId, 
                          _date, 
                          _memberMeals,
                          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meals logged securely!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        setState(() => _isLoading = false);
                      }
                    },
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save All Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
