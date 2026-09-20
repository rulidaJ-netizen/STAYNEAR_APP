part of '../main.dart';

/// Profiles persist through the authenticated Firebase account only.
class ProfileStorage {
  ProfileStorage({FirebaseBackend? backend})
    : _backend = backend ?? FirebaseBackend();
  final FirebaseBackend _backend;
  Future<void> save(UserProfile user) async {
    await _backend.saveProfile(user);
  }

  Future<UserProfile> load(UserProfile user) async {
    if (_backend.uid != user.id) {
      throw StateError('Please sign in to this account.');
    }
    return _backend.loadProfile();
  }
}
