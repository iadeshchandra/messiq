import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../controllers/duty_provider.dart';
import '../../auth/models/user_model.dart';

class DutyRosterScreen extends ConsumerStatefulWidget {
  final String messId;
  const DutyRosterScreen({super.key, required this.messId});

  @override
  ConsumerState<DutyRosterScreen> createState() => _DutyRosterScreenState();
}

class _DutyRosterScreenState extends ConsumerState<DutyRosterScreen> {
  
  void _showAddDutySheet(BuildContext context, WidgetRef ref, List<UserModel> members) {
    final titleCtrl = TextEditingController();
    UserModel? selectedMember;
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedTime; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  const Text('Assign Duty', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g., Friday Bazaar, Room Cleaning...',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonFormField<UserModel>(
                      value: selectedMember,
                      hint: const Text('Select Member'),
                      decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primaryIndigo)),
                      items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                      onChanged: (val) => setSheetState(() => selectedMember = val),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: AppTheme.backgroundLight,
                          leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryIndigo),
                          title: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(selectedDate.toString().split(' ')[0], style: const TextStyle(fontSize: 12)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)), 
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: AppTheme.backgroundLight,
                          leading: const Icon(Icons.access_time_rounded, color: Colors.orange),
                          title: const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(selectedTime != null ? selectedTime!.format(ctx) : 'Anytime', style: const TextStyle(fontSize: 12)),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedTime = picked);
                            }
                          },
                          onLongPress: () => setSheetState(() => selectedTime = null), 
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isNotEmpty && selectedMember != null) {
                          DateTime? finalDueTime;
                          if (selectedTime != null) {
                            finalDueTime = DateTime(
                              selectedDate.year, 
                              selectedDate.month, 
                              selectedDate.day, 
                              selectedTime!.hour, 
                              selectedTime!.minute
                            );
                          }

                          await ref.read(dutyControllerProvider).addDuty(
                            messId: widget.messId,
                            title: titleCtrl.text,
                            assignedToUid: selectedMember!.uid,
                            assignedToName: selectedMember!.name,
                            assignedDate: selectedDate,
                            dueTime: finalDueTime, 
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Assign Duty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dutiesAsync = ref.watch(messDutiesProvider(widget.messId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentRoleAsync = ref.watch(currentMemberRoleProvider(widget.messId));
    
    final membersAsync = ref.watch(messMembersDirectoryProvider(widget.messId));
    final isManager = currentRoleAsync.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Duty Roster', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      floatingActionButton: isManager ? FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryIndigo,
        onPressed: () {
          final members = membersAsync.value ?? [];
          if (members.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading members... please try again.')));
            return;
          }
          _showAddDutySheet(context, ref, members);
        },
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Assign Duty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      body: dutiesAsync.when(
        data: (duties) {
          if (duties.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No duties assigned', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('The manager hasn\'t assigned any tasks yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final sortedDuties = List.of(duties)..sort((a, b) {
            if (a.isCompleted == b.isCompleted) {
              final aTime = a.dueTime ?? a.assignedDate;
              final bTime = b.dueTime ?? b.assignedDate;
              return aTime.compareTo(bTime);
            }
            return a.isCompleted ? 1 : -1;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: sortedDuties.length,
            itemBuilder: (context, index) {
              final duty = sortedDuties[index];
              final isMyDuty = currentUser != null && duty.assignedToUid == currentUser.uid;
              
              bool isPastDue = false;
              if (!duty.isCompleted) {
                if (duty.dueTime != null) {
                  isPastDue = DateTime.now().isAfter(duty.dueTime!);
                } else {
                  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  final assignedDay = DateTime(duty.assignedDate.year, duty.assignedDate.month, duty.assignedDate.day);
                  isPastDue = assignedDay.isBefore(today);
                }
              }

              String timeDisplay = '';
              if (duty.dueTime != null) {
                final h = duty.dueTime!.hour > 12 ? duty.dueTime!.hour - 12 : (duty.dueTime!.hour == 0 ? 12 : duty.dueTime!.hour);
                final amPm = duty.dueTime!.hour >= 12 ? 'PM' : 'AM';
                final m = duty.dueTime!.minute.toString().padLeft(2, '0');
                timeDisplay = ' by $h:$m $amPm';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: duty.isCompleted ? Colors.grey.shade50 : (isPastDue ? Colors.red.shade50 : (isMyDuty ? AppTheme.primaryIndigo.withOpacity(0.05) : Colors.white)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isMyDuty && !duty.isCompleted ? AppTheme.primaryIndigo.withOpacity(0.5) : (isPastDue ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Checkbox(
                    value: duty.isCompleted,
                    activeColor: Colors.teal,
                    onChanged: (isMyDuty || isManager) 
                        ? (_) => ref.read(dutyControllerProvider).toggleDutyStatus(widget.messId, duty.id, duty.isCompleted)
                        : null,
                  ),
                  title: Text(
                    duty.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: duty.isCompleted ? Colors.grey : AppTheme.textDark,
                      decoration: duty.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // FIXED: Changed to Wrap to prevent overflow on narrow screens
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.person_rounded, size: 14, color: isMyDuty ? AppTheme.primaryIndigo : Colors.grey),
                          const SizedBox(width: 4),
                          Text(isMyDuty ? 'Assigned to You' : 'Assigned to ${duty.assignedToName}', style: TextStyle(color: isMyDuty ? AppTheme.primaryIndigo : Colors.grey, fontWeight: isMyDuty ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // FIXED: Changed to Wrap to prevent overflow on narrow screens
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: isPastDue ? Colors.redAccent : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${duty.assignedDate.toString().split(' ')[0]}$timeDisplay', 
                            style: TextStyle(color: isPastDue ? Colors.redAccent : Colors.grey, fontWeight: isPastDue ? FontWeight.bold : FontWeight.normal)
                          ),
                          if (isPastDue) const Text(' (Past Due!)', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  trailing: isManager
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => ref.read(dutyControllerProvider).deleteDuty(widget.messId, duty.id),
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
