import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:stay_near/main.dart';

const testPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC';

/// Only authentication credentials are simulated here. All repository methods,
/// serialization, streams and upload handling execute the production code.
class TestFirebaseBackend extends FirebaseBackend {
  TestFirebaseBackend({Future<void> Function(User user)? synchronizeAuthClaims})
    : this._(TestSupabaseStorageService(), synchronizeAuthClaims);
  TestFirebaseBackend._(this.storage, synchronizeAuthClaims)
    : super(
        auth: MockFirebaseAuth(verifyEmailAutomatically: false),
        firestore: FakeFirebaseFirestore(),
        imageStorage: storage,
        synchronizeAuthClaims: synchronizeAuthClaims ?? (_) async {},
      );
  final TestSupabaseStorageService storage;
  final Map<String, ({MockUser user, String password})> _accounts = {};

  @override
  Future<UserProfile> register(UserProfile draft) async {
    if (_accounts.containsKey(draft.email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    final profile = await super.register(draft);
    _accounts[draft.email] = (
      user: MockUser(uid: profile.id, email: profile.email),
      password: draft.password,
    );
    return profile;
  }

  @override
  Future<UserProfile> login(
    String email,
    String password, {
    UserRole? expectedRole,
  }) {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    (auth as MockFirebaseAuth).mockUser = account.user;
    return super.login(email, password, expectedRole: expectedRole);
  }

  Future<UserProfile> signUpAndLogin(UserProfile draft) async {
    await register(draft);
    return login(draft.email, draft.password);
  }

  Future<void> seedListings() async {
    for (final (id, name) in [
      ('sample-jhes', 'Jhes BH'),
      ('sample-zaframar', 'ZafraMar BH'),
    ]) {
      final listing = Listing(
        id: id,
        ownerId: 'fixture-owner',
        title: name,
        address: 'Clarin',
        price: 1200,
        image: null,
        availableRooms: 2,
        totalRooms: 2,
      );
      await db.collection('listings').doc(id).set({
        ...FirebaseBackend.listingData(listing),
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class TestSupabaseStorageService extends SupabaseStorageService {
  final Map<String, List<int>> _objects = {};
  var _nextId = 0;

  Iterable<String> get paths => _objects.keys;
  List<int>? getData(String url) => _objects[storagePath(url)];

  @override
  Future<String> uploadListingImage(String firebaseUid, String source) =>
      _upload('listings/$firebaseUid', source);

  @override
  Future<List<String>> uploadListingImages(
    String firebaseUid,
    Iterable<String> sources,
  ) async {
    final results = <String>[];
    for (final source in sources) {
      results.add(await uploadListingImage(firebaseUid, source));
    }
    return results;
  }

  @override
  Future<String> uploadProfileImage(String firebaseUid, String source) =>
      _upload('profiles/$firebaseUid', source);

  Future<String> _upload(String folder, String source) async {
    if (source.startsWith('http')) return source;
    final data = UriData.parse(source);
    final extension = data.mimeType == 'image/jpeg'
        ? 'jpg'
        : data.mimeType.split('/').last;
    final path = '$folder/test-${_nextId++}.$extension';
    _objects[path] = data.contentAsBytes();
    return 'https://drlaskltdvphtkjualvx.supabase.co/storage/v1/object/public/${SupabaseStorageService.bucketName}/$path';
  }

  @override
  Future<void> deleteImage(String urlOrPath) async {
    final path = storagePath(urlOrPath);
    if (path != null) _objects.remove(path);
  }
}
