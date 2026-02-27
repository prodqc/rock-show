import '../models/user_model.dart';

abstract class UserRepository {
  Stream<UserModel?> watchUser(String uid);
  Future<UserModel?> getUser(String uid);
  Future<void> createOrUpdateUser(UserModel user);
  Future<void> updateUser(String uid, Map<String, dynamic> updates);
}
