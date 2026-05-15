import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChange;
});

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(authRepository: ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;
  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(false);

  Future<void> signUp(String email, String password, String name) async {
    state = true;
    try {
      await _authRepository.signUp(email, password, name);
    } finally {
      state = false;
    }
  }

  Future<void> login(String email, String password) async {
    state = true;
    try {
      await _authRepository.login(email, password);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
