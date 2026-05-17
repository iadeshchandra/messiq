import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/mess_repository.dart';
import '../../auth/controllers/auth_controller.dart';

final messControllerProvider = StateNotifierProvider<MessController, bool>((ref) {
  return MessController(messRepository: ref.read(messRepositoryProvider), ref: ref);
});

class MessController extends StateNotifier<bool> {
  final MessRepository _messRepository;
  final Ref _ref;

  MessController({required MessRepository messRepository, required Ref ref})
      : _messRepository = messRepository,
        _ref = ref,
        super(false);

  Future<void> createMess(String name) async {
    state = true;
    try {
      final userId = _ref.read(authStateProvider).value!.uid;
      await _messRepository.createMess(name, userId);
    } finally {
      state = false;
    }
  }

  Future<void> joinMess(String inviteCode) async {
    state = true;
    try {
      final userId = _ref.read(authStateProvider).value!.uid;
      await _messRepository.joinMess(inviteCode, userId);
    } finally {
      state = false;
    }
  }

  // 🛡️ DWARAPALA (MANAGER) ACTIONS
  
  Future<void> approveMember(String messId, String targetUid) async {
    state = true;
    try {
      await _messRepository.approveMember(messId, targetUid);
    } finally {
      state = false;
    }
  }

  Future<void> rejectMember(String messId, String targetUid) async {
    state = true;
    try {
      await _messRepository.removeOrRejectMember(messId, targetUid);
    } finally {
      state = false;
    }
  }
}
