import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../models/notification_model.dart';

// Streams notifications and filters them for the current user
final messNotificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, messId) {
  final user = ref.watch(authStateProvider).value;
  final memberRoleData = ref.watch(currentMemberRoleProvider(messId)).value;
  
  if (user == null || memberRoleData == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('messes')
      .doc(messId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final allNotifs = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
        
        // SMART FILTERING: Only show notifications meant for this user's role or UID
        return allNotifs.where((notif) {
          bool roleMatch = notif.targetRole == null || notif.targetRole == memberRoleData.role;
          bool uidMatch = notif.targetUid == null || notif.targetUid == user.uid;
          return roleMatch && uidMatch;
        }).toList();
      });
});

// Calculates how many notifications the user hasn't clicked yet
final unreadNotificationCountProvider = Provider.family<int, String>((ref, messId) {
  final user = ref.watch(authStateProvider).value;
  final notifications = ref.watch(messNotificationsProvider(messId)).value ?? [];
  
  if (user == null) return 0;
  return notifications.where((n) => !n.readBy.contains(user.uid)).length;
});

// Action controller to mark notifications as read
final notificationControllerProvider = Provider((ref) => NotificationController());

class NotificationController {
  Future<void> markAsRead(String messId, String notificationId, String uid) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('notifications')
        .doc(notificationId)
        .update({
          'readBy': FieldValue.arrayUnion([uid])
        });
  }
}
