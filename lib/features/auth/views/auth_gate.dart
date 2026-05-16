import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mess/views/mess_selection_screen.dart';
import '../../mess/views/waiting_room_screen.dart';
import '../../mess/controllers/active_mess_provider.dart';
import '../../dashboard/controllers/dashboard_providers.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../controllers/auth_controller.dart';
import 'welcome_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final messState = ref.watch(activeMessProvider);
          return messState.when(
            data: (messId) {
              // SAFETY CHECK: Ensure messId is valid before letting them in
              if (messId != null && messId.isNotEmpty) {
                final memberRole = ref.watch(currentMemberRoleProvider(messId));
                return memberRole.when(
                  data: (member) {
                    if (member?.status == 'pending') {
                      return WaitingRoomScreen(messId: messId); 
                    }
                    return DashboardScreen(messId: messId); 
                  },
                  loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const Scaffold(body: Center(child: Text('Error loading status'))),
                );
              }
              return const MessSelectionScreen();
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(body: Center(child: Text('Error loading workspace: $e'))),
          );
        }
        return const WelcomeScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
