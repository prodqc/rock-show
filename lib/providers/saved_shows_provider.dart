import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Stream of show IDs that the current user has saved.
final savedShowIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return Stream.value({});
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .collection('saved_shows')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

/// Toggle save/unsave a show for a given user.
Future<void> toggleSaveShow({
  required String uid,
  required String showId,
}) async {
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('saved_shows')
      .doc(showId);
  final snap = await docRef.get();
  if (snap.exists) {
    await docRef.delete();
  } else {
    await docRef.set({'savedAt': FieldValue.serverTimestamp()});
  }
}
