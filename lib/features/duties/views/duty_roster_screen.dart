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
    TimeOfDay? selectedTime; // NEW: Precise time tracker

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

                  // Date & Time Row
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
                          subtitle: Text(selectedTime != null ? selectedTime!.format(ctx) : 'Anytime', style: const TextStyle(fontSize: 1
