import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/mess_repository.dart';

final messControllerProvider = StateNotifierProvider<MessController, bool>((ref) {
  return MessController(messRepository: ref.watch(messRepositoryProvider));
});

class MessController extends StateNotifier<bool> {
  final MessRepository _messRepository;

  MessController({required MessRepository messRepository})
      : _messRepository = messRepository,
        super(false);

  Future<void> createMess(String name) async {
    state = true;
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _messRepository.createMess(name, userId);
    } finally {
      state = false;
    }
  }

  Future<void> joinMess(String inviteCode) async {
    state = true;
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _messRepository.joinMess(inviteCode.toUpperCase(), userId);
    } finally {
      state = false;
    }
  }
}
