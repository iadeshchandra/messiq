import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mess/views/mess_selection_screen.dart';
import '../../mess/controllers/active_mess_provider.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../controllers/auth_controller.dart';
import 'welcome_screen.dart'; // IMPORTANT: Now imports the Welcome Screen

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
              if (messId != null) {
                return DashboardScreen(messId: messId);
              }
              return const MessSelectionScreen();
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(body: Center(child: Text('Error loading workspace: $e'))),
          );
        }
        // If the user is NOT logged in, show the new Onboarding Welcome Carousel
        return const WelcomeScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
