import '../models/contact_submission_model.dart';
import '../models/venue_claim_model.dart';
import '../models/venue_model.dart';

abstract class ModerationRepository {
  Future<String> submitContact(ContactSubmissionModel submission);

  Future<String> submitVenueClaim({
    required VenueClaimModel claim,
    required ContactSubmissionModel contactSubmission,
  });

  Stream<List<VenueModel>> watchPendingVenues({int limit = 100});
  Stream<List<VenueClaimModel>> watchPendingVenueClaims({int limit = 100});

  Future<void> approveVenue({
    required String venueId,
    required String adminUid,
  });

  Future<void> rejectVenue({
    required String venueId,
    required String adminUid,
    String? reason,
  });

  Future<void> approveVenueClaim({
    required String claimId,
    required String adminUid,
  });

  Future<void> rejectVenueClaim({
    required String claimId,
    required String adminUid,
    String? reason,
  });
}
