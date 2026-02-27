import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/impl/firestore_user_repository.dart';
import '../repositories/user_repository.dart';
import 'auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository();
});

final currentUserDocProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(authUser.uid);
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  return user?.role == 'admin';
});

final isVenueOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  return user?.role == 'venue_owner';
});
