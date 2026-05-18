import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../controllers/poll_provider.dart';
import '../../ai_insights/controllers/meal_optimizer_provider.dart';

class PollsScreen extends ConsumerStatefulWidget {
  final String messId;
  const PollsScreen({super.key, required this.messId});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(text: 'Fish Curry 🐟'),
    TextEditingController(text: 'Egg Bhuna 🥚'),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showCreatePollSheet(MealRateInsight? aiInsight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Meal Poll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              
              // AI OPTIMIZER INTERVENTION
              if (aiInsight != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aiInsight.isHigh ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: aiInsight.isHigh ? Colors.redAccent.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(aiInsight.isHigh ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: aiInsight.isHigh ? Colors.redAccent : Colors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(aiInsight.title, style: TextStyle(fontWeight: FontWeight.bold, color: aiInsight.isHigh ? Colors.redAccent : Colors.teal, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(aiInsight.message, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                      if (aiInsight.suggestedLowCostMeals.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: aiInsight.suggestedLowCostMeals.map((meal) => Chip(
                            label: Text(meal, style: const TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.redAccent.shade200,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        )
                      ]
                    ],
                  ),
                ),

              TextField(
                controller: _questionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'What is the voting question?', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              ...List.generate(_optionControllers.length, (idx) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _optionControllers[idx],
                  decoration: InputDecoration(labelText: 'Option ${idx + 1}', filled: true, fillColor: AppTheme.backgroundLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              )),
              TextButton.icon(
                onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                label: const Text('Add Alternative Option', style: TextStyle(color: Colors.orange)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    final cleanOptions = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                    if (_questionController.text.isNotEmpty && cleanOptions.length >= 2) {
                      await ref.read(pollControllerProvider.notifier).createCustomMealPoll(
                        messId: widget.messId,
                        question: _questionController.text.trim(),
                        options: cleanOptions,
                      );
                      _questionController.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Launch Live Poll', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollsAsync = ref.watch(messPollsProvider(widget.messId));
    final memberRole = ref.watch(currentMemberRoleProvider(widget.messId));
    final currentUid = ref.watch(authStateProvider).value?.uid;
    final aiInsight = ref.watch(mealRateOptimizerProvider(widget.messId));
    
    final isManager = memberRole.value?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Meal Voting Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              backgroundColor: Colors.orange,
              onPressed: () => _showCreatePollSheet(aiInsight),
              icon: const Icon(Icons.poll_rounded, color: Colors.white),
              label: const Text('New Poll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ballot_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active polls yet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: polls.length,
            itemBuilder: (ctx, idx) {
              final poll = polls[idx];
              final totalVotes = poll.votes.length;
              final userSelection = poll.votes[currentUid];

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: poll.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              poll.isActive ? 'ACTIVE VOTE' : 'CLOSED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: poll.isActive ? Colors.green : Colors.grey),
                            ),
                          ),
                          if (isManager && poll.isActive)
                            TextButton(
                              onPressed: () => ref.read(pollControllerProvider.notifier).closePoll(messId: widget.messId, pollId: poll.id),
                              child: const Text('Close Poll', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(poll.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 4),
                      Text('Launched by ${poll.addedByName} • $totalVotes votes registered', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 32),
                      
                      ...poll.options.map((option) {
                        final optionVotes = poll.votes.values.where((v) => v == option).length;
                        final percentage = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;
                        final isMyVote = userSelection == option;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: poll.isActive
                                ? () => ref.read(pollControllerProvider.notifier).castVote(messId: widget.messId, pollId: poll.id, selectedOption: option)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Container(
                                  height: 48,
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(16)),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  height: 48,
                                  width: MediaQuery.of(context).size.width * 0.75 * percentage,
                                  decoration: BoxDecoration(
                                    color: isMyVote ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (isMyVote) const Icon(Icons.check_circle, color: Colors.orange, size: 18),
                                          if (isMyVote) const SizedBox(width: 8),
                                          Text(option, style: TextStyle(fontWeight: isMyVote ? FontWeight.bold : FontWeight.w500, color: AppTheme.textDark)),
                                        ],
                                      ),
                                      Text('${(percentage * 100).toStringAsFixed(0)}% ($optionVotes)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
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
