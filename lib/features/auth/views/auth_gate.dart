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
              if (messId != null && messId.isNotEmpty) {
                final memberRole = ref.watch(currentMemberRoleProvider(messId));
                return memberRole.when(
                  data: (member) {
                    // Fallback check: If the member doc is somehow null right after joining, show loading
                    if (member == null) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    if (member.status == 'pending') {
                      return WaitingRoomScreen(messId: messId); 
                    }
                    return DashboardScreen(messId: messId); 
                  },
                  loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                  error: (e, __) => Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'System Error:\n$e', 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const MessSelectionScreen();
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(body: Center(child: Text('Workspace Error: $e'))),
          );
        }
        return const WelcomeScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
    );
  }
}
