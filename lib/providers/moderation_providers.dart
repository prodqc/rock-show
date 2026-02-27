import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/venue_claim_model.dart';
import '../models/venue_model.dart';
import '../repositories/impl/firestore_moderation_repository.dart';
import '../repositories/moderation_repository.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return FirestoreModerationRepository();
});

final pendingVenuesProvider = StreamProvider<List<VenueModel>>((ref) {
  return ref.watch(moderationRepositoryProvider).watchPendingVenues();
});

final pendingVenueClaimsProvider = StreamProvider<List<VenueClaimModel>>((ref) {
  return ref.watch(moderationRepositoryProvider).watchPendingVenueClaims();
});
