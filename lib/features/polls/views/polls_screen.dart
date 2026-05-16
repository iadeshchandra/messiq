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
                    decoration: InputDecoration(
                      hintText: 'e.g., What should we eat for Friday lunch?',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
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
                          await ref.read(pollControllerProvider).createPoll(widget.messId, questionCtrl.text, options);
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
                              Text('Asked by ${poll.addedByName} • $totalVotes votes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (!poll.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Text('CLOSED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (isManager)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'close' && poll.isActive) {
                                ref.read(pollControllerProvider).closePoll(widget.messId, poll.id);
                              } else if (value == 'delete') {
                                ref.read(pollControllerProvider).deletePoll(widget.messId, poll.id);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              if (poll.isActive) const PopupMenuItem(value: 'close', child: Text('Close Poll')),
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
                          if (poll.isActive && currentUser != null) {
                            ref.read(pollControllerProvider).voteOnPoll(widget.messId, poll.id, optIndex);
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
                              // Progress Bar Background
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  height: 48,
                                  color: isMyVote ? AppTheme.primaryIndigo.withOpacity(0.15) : Colors.grey.shade100,
                                ),
                              ),
                              // Text Content
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
