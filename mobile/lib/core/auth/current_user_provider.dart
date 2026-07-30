import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auth_storage.dart';
import 'current_user.dart';

final currentUserProvider = FutureProvider<CurrentUser?>((ref) async {
  final storage = ref.watch(authStorageProvider);
  final token = await storage.readToken();
  return CurrentUser.fromToken(token);
});
