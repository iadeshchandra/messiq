import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/notification_provider.dart';

// Import target screens for Deep Linking
import '../../duties/views/duty_roster_screen.dart';
import '../../polls/views/polls_screen.dart';
import '../../profile/views/profile_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  final String messId;
  const NotificationsScreen({super.key, required this.messId});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _handleDeepLink(BuildContext context, String? route) {
    if (route == null) return;
    
    switch (route) {
      case 'duties':
        Navigator.push(context, MaterialPageRoute(builder: (_) => DutyRosterScreen(messId: messId)));
        break;
      case 'polls':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PollsScreen(messId: messId)));
        break;
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(messId: messId)));
        break;
      default:
        // If route is unknown, do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(messNotificationsProvider(messId));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('You have no new notifications.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = currentUser != null && !notif.readBy.contains(currentUser.uid);

              return GestureDetector(
                onTap: () async {
                  // 1. Mark as read
                  if (isUnread && currentUser != null) {
                    await ref.read(notificationControllerProvider).markAsRead(messId, notif.id, currentUser.uid);
                  }
                  // 2. Deep Link to the specific screen if a route exists
                  if (context.mounted) {
                    _handleDeepLink(context, notif.targetRoute);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnread ? AppTheme.primaryIndigo.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isUnread ? Border.all(color: AppTheme.primaryIndigo.withOpacity(0.3)) : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUnread ? AppTheme.primaryIndigo : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded, 
                          color: isUnread ? Colors.white : Colors.grey, 
                          size: 20
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(notif.title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal, fontSize: 16, color: AppTheme.textDark))),
                                Text(_timeAgo(notif.createdAt), style: TextStyle(color: isUnread ? AppTheme.primaryIndigo : Colors.grey, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(notif.body, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                            
                            // Visual cue that this notification is clickable
                            if (notif.targetRoute != null) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Text('Tap to view', style: TextStyle(fontSize: 12, color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primaryIndigo),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                      ]
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
