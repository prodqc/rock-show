import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _db;

  FirestoreUserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  @override
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    final payload = user.toFirestore();
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.uid).set(payload, SetOptions(merge: true));
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(uid).update(updates);
  }
}
