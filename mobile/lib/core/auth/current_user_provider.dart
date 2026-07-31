import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auth_storage.dart';
import 'current_user.dart';

class CurrentUserNotifier extends AsyncNotifier<CurrentUser?> {
  @override
  Future<CurrentUser?> build() async {
    final storage = ref.read(authStorageProvider);
    final token = await storage.readToken();
    return CurrentUser.fromToken(token);
  }

  /// Atualiza o usuário corrente de forma síncrona — usado após login.
  void setUser(CurrentUser? user) {
    state = AsyncData(user);
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, CurrentUser?>(
  CurrentUserNotifier.new,
);
