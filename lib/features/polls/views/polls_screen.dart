import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../controllers/poll_provider.dart';

class PollsScreen extends ConsumerStatefulWidget {
  final String messId;
  const PollsScreen({super.key, required this.messId});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  void _showCreatePollSheet(BuildContext context, WidgetRef ref) {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];
    DateTime? selectedDeadline;

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
                  const Text('Ask the Mess', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: questionCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g., What should we eat for Friday lunch?',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: AppTheme.backgroundLight,
                    leading: const Icon(Icons.timer_outlined, color: AppTheme.primaryIndigo),
                    title: const Text('Set Deadline (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      selectedDeadline == null 
                        ? 'No deadline (manual close)' 
                        : 'Closes on ${selectedDeadline!.toString().substring(0, 16)}',
                      style: TextStyle(color: selectedDeadline == null ? Colors.grey : AppTheme.textDark),
                    ),
                    trailing: selectedDeadline != null 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          onPressed: () => setSheetState(() => selectedDeadline = null),
                        )
                      : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null && ctx.mounted) {
                        final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                        if (time != null) {
                          setSheetState(() {
                            selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...List.generate(optionCtrls.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionCtrls[index],
                              decoration: InputDecoration(
                                hintText: 'Option ${index + 1}',
                                filled: true,
                                fillColor: AppTheme.backgroundLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          if (optionCtrls.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () {
                                setSheetState(() => optionCtrls.removeAt(index));
                              },
                            )
                        ],
                      ),
                    );
                  }),
                  if (optionCtrls.length < 5)
                    TextButton.icon(
                      onPressed: () => setSheetState(() => optionCtrls.add(TextEditingController())),
                      icon: const Icon(Icons.add, color: AppTheme.primaryIndigo),
                      label: const Text('Add Option', style: TextStyle(color: AppTheme.primaryIndigo)),
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
                        if (questionCtrl.text.isNotEmpty && optionCtrls.every((c) => c.text.isNotEmpty)) {
                          final options = optionCtrls.map((c) => c.text).toList();
                          await ref.read(pollControllerProvider).createPoll(
                            widget.messId, 
                            questionCtrl.text, 
                            options,
                            expiresAt: selectedDeadline, 
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Post Poll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    final pollsAsync = ref.watch(messPollsProvider(widget.messId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentRoleAsync = ref.watch(currentMemberRoleProvider(widget.messId));

    final isManager = currentRoleAsync.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Meal Polls', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryIndigo,
        onPressed: () => _showCreatePollSheet(context, ref),
        icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
        label: const Text('Create Poll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.poll_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active polls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('Create a poll to ask the mess a question.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              final totalVotes = poll.votes.length;
              final myVoteIndex = currentUser != null ? poll.votes[currentUser.uid] : null;

              final bool isExpired = poll.expiresAt != null && DateTime.now().isAfter(poll.expiresAt!);
              final bool isActuallyActive = poll.isActive && !isExpired;

              String deadlineText = '';
              if (poll.expiresAt != null) {
                if (isExpired) {
                  deadlineText = 'Time is up';
                } else {
                  final diff = poll.expiresAt!.difference(DateTime.now());
                  if (diff.inDays > 0) deadlineText = 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
                  else if (diff.inHours > 0) deadlineText = 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
                  else deadlineText = 'Ends in ${diff.inMinutes}m';
                }
              }

            return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(poll.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              const SizedBox(height: 4),
                              // FIXED: Changed to Wrap to prevent overflow!
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Asked by ${poll.addedByName} • $totalVotes votes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (poll.expiresAt != null) ...[
                                    const Text(' • ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Icon(Icons.timer_outlined, size: 12, color: isExpired ? Colors.redAccent : Colors.orange),
                                    const SizedBox(width: 2),
                                    Text(deadlineText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isExpired ? Colors.redAccent : Colors.orange)),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isActuallyActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('CLOSED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (isManager)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'close' && isActuallyActive) {
                                ref.read(pollControllerProvider).closePoll(widget.messId, poll.id);
                              } else if (value == 'delete') {
                                ref.read(pollControllerProvider).deletePoll(widget.messId, poll.id);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              if (isActuallyActive) const PopupMenuItem(value: 'close', child: Text('Close Poll')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Poll', style: TextStyle(color: Colors.red))),
                            ],
                          )
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(poll.options.length, (optIndex) {
                      final option = poll.options[optIndex];
                      final voteCount = poll.votes.values.where((v) => v == optIndex).length;
                      final percentage = totalVotes > 0 ? voteCount / totalVotes : 0.0;
                      final isMyVote = myVoteIndex == optIndex;

                      return GestureDetector(
                        onTap: () {
                          if (isActuallyActive && currentUser != null) {
                            ref.read(pollControllerProvider).voteOnPoll(widget.messId, poll.id, optIndex);
                          } else if (!isActuallyActive) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voting is closed for this poll.')));
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isMyVote ? AppTheme.primaryIndigo : Colors.grey.shade300, width: isMyVote ? 2 : 1),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  height: 48,
                                  color: isMyVote ? AppTheme.primaryIndigo.withOpacity(0.15) : Colors.grey.shade100,
                                ),
                              ),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (isMyVote) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.check_circle_rounded, color: AppTheme.primaryIndigo, size: 18)),
                                          Expanded(child: Text(option, style: TextStyle(fontWeight: isMyVote ? FontWeight.bold : FontWeight.normal, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
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
