part of '../main.dart';

String backendMessage(Object error) {
  if (error is FirebaseAuthException) {
    debugPrint('AUTH ERROR CODE: ${error.code}');
    debugPrint('AUTH ERROR MESSAGE: ${error.message}');
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Invalid email or password.',
      'email-already-in-use' =>
        'This email is already registered. Please log in.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' => 'Please use a password with at least 6 characters.',
      'requires-recent-login' =>
        'Please log out and log in again before changing your email.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'user-disabled' => 'This account is disabled.',
      'operation-not-allowed' => 'Email/password sign-in is not enabled.',
      'network-request-failed' =>
        'Unable to connect to Firebase. Please check your internet connection.',
      _ => 'Firebase could not complete this request. Please try again.',
    };
  }
  if (error is FirebaseException) {
    debugPrint('FIREBASE ERROR: $error');
    return error.code == 'permission-denied' || error.code == 'unauthorized'
        ? 'You do not have permission to access this Firebase data.'
        : 'Firebase could not complete this request. Please try again.';
  }
  if (error is StateError) {
    debugPrint('BACKEND STATE ERROR: ${error.message}');
    return error.message.toString();
  }
  if (error is FormatException) return error.message;
  debugPrint('BACKEND ERROR: $error');
  return 'Unable to complete this action. Please try again.';
}

void _validateCredentials(String email, [String? password]) {
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
    throw FirebaseAuthException(code: 'invalid-email');
  }
  if (password != null && password.length < 6) {
    throw FirebaseAuthException(code: 'weak-password');
  }
}

String _text(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;
int _integer(dynamic value) =>
    value is num && value.isFinite ? value.toInt() : 0;
double? _number(dynamic value) =>
    value is num && value.isFinite ? value.toDouble() : null;
List<String> _strings(dynamic value) =>
    value is List ? value.whereType<String>().toList() : [];
Map<String, String> _stringMap(dynamic value) => value is Map
    ? {
        for (final entry in value.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      }
    : {};

/// Firebase is the runtime source of truth. SDK dependencies are injectable for
/// tests; widgets continue to use the existing models and ChangeNotifier store.
class FirebaseBackend {
  FirebaseBackend({
    this._auth,
    this._firestore,
    SupabaseStorageService? imageStorage,
    Future<void> Function(User user)? synchronizeAuthClaims,
  }) : _imageStorage = imageStorage ?? SupabaseStorageService(),
       _synchronizeAuthClaims =
           synchronizeAuthClaims ?? _synchronizeAuthenticatedRole;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final SupabaseStorageService _imageStorage;
  final Future<void> Function(User user) _synchronizeAuthClaims;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;
  final _location = PropertyLocationService();
  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('Please log in again.'));

  Future<void> synchronizeAuthenticatedRole() async {
    final user = auth.currentUser ?? (throw StateError('Please log in again.'));
    await _synchronizeAuthClaims(user);
  }

  static Map<String, dynamic> profileData(UserProfile user) => {
    'uid': user.id,
    'firstName': user.firstName,
    'middleName': user.middleName,
    'lastName': user.lastName,
    'fullName': user.fullName,
    'email': user.email,
    'birthday': user.birthday,
    'gender': user.gender,
    'phoneNumber': user.contact,
    'address': user.address,
    'role': user.role == UserRole.landlord ? 'landowner' : 'boarder',
    'profilePhotoUrl': user.profilePhoto,
  };

  static UserProfile profileFromData(String id, Map<String, dynamic> data) {
    final role = data['role'];
    final storedPhoto = _text(data['profilePhotoUrl']).trim();
    if (role != 'boarder' && role != 'landowner') {
      throw StateError(
        'Your account profile has no valid role. Please contact support.',
      );
    }
    return UserProfile(
      accountId: id,
      firstName: _text(data['firstName']),
      middleName: _text(data['middleName']),
      lastName: _text(data['lastName']),
      displayName: data['fullName'] is String ? data['fullName'] : null,
      email: _text(data['email']),
      birthday: _text(data['birthday']),
      gender: _text(data['gender']),
      contact: _text(data['phoneNumber'], _text(data['contact'])),
      address: _text(data['address']),
      profilePhoto: storedPhoto.isEmpty ? null : storedPhoto,
      role: role == 'landowner' ? UserRole.landlord : UserRole.boarder,
    );
  }

  Future<UserProfile> loadProfile() async {
    final user = auth.currentUser ?? (throw StateError('Please log in again.'));
    final document = await db.collection('users').doc(user.uid).get();
    if (!document.exists) {
      throw StateError(
        'Your account profile is missing. Please contact support.',
      );
    }
    final data = document.data()!;
    // Only Auth's verified email becomes the persisted account email.
    if (user.email != null && data['email'] != user.email) {
      await db.collection('users').doc(user.uid).update({
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      data['email'] = user.email;
    }
    return profileFromData(user.uid, data);
  }

  Future<UserProfile> register(UserProfile draft) async {
    _validateCredentials(draft.email, draft.password);
    final credential = await auth.createUserWithEmailAndPassword(
      email: draft.email.trim(),
      password: draft.password,
    );
    final user = credential.user!;
    final data = profileData(draft)..['uid'] = user.uid;
    data['email'] = user.email;
    data['profilePhotoUrl'] = null;
    try {
      // The callable uses the caller's verified Auth context and assigns the
      // claim with the Admin SDK. Refresh only after it has completed.
      await _synchronizeAuthClaims(user);
      await db.collection('users').doc(user.uid).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Roll back Auth if profile creation fails so registration can be retried.
      try {
        await user.delete();
      } catch (_) {
        /* Surface the original write failure. */
      }
      await auth.signOut();
      rethrow;
    }
    await auth.signOut(); // Preserve the existing register -> login flow.
    return profileFromData(user.uid, data);
  }

  Future<UserProfile> login(
    String email,
    String password, {
    UserRole? expectedRole,
  }) async {
    _validateCredentials(email);
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await synchronizeAuthenticatedRole();
      final profile = await loadProfile();
      if (expectedRole != null && profile.role != expectedRole) {
        final actualRole = profile.role == UserRole.boarder
            ? 'Boarder'
            : 'Landowner';
        throw StateError(
          'This account is registered as a $actualRole. Select $actualRole to log in.',
        );
      }
      return profile;
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    _validateCredentials(email);
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Returns the saved profile and whether verification was sent for a new email.
  Future<({UserProfile profile, bool emailVerificationSent})> saveProfile(
    UserProfile draft,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.uid != draft.id) {
      throw StateError('The active account changed. Please log in again.');
    }
    final current = await loadProfile();
    if (current.role != draft.role) {
      throw StateError('Account roles cannot be changed here.');
    }
    final emailChanged =
        draft.email.trim().toLowerCase() != user.email?.toLowerCase();
    if (emailChanged) await user.verifyBeforeUpdateEmail(draft.email.trim());
    if (draft.profilePhoto != null &&
        SupabaseStorageService._isRemoteUrl(draft.profilePhoto!) &&
        draft.profilePhoto != current.profilePhoto) {
      throw const FormatException(
        'Please select a profile photo from this device.',
      );
    }
    String? uploadedPhoto;
    try {
      final photo = draft.profilePhoto == null
          ? null
          : await _imageStorage.uploadProfileImage(
              user.uid,
              draft.profilePhoto!,
            );
      if (photo != draft.profilePhoto) uploadedPhoto = photo;
      final saved = draft.withProfileEdits(
        fullName: draft.fullName,
        phone: draft.contact,
        email: user.email ?? current.email,
        address: draft.address,
        photo: photo,
      );
      await db.collection('users').doc(user.uid).update({
        'fullName': saved.fullName,
        'phoneNumber': saved.contact,
        'address': saved.address,
        'email': saved.email,
        'profilePhotoUrl': saved.profilePhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (current.profilePhoto != null &&
          current.profilePhoto != saved.profilePhoto) {
        await _imageStorage.deleteImage(current.profilePhoto!);
      }
      return (profile: saved, emailVerificationSent: emailChanged);
    } catch (error, stackTrace) {
      debugPrint('PROFILE SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (uploadedPhoto != null) {
        await _imageStorage.deleteImage(uploadedPhoto);
      }
      rethrow;
    }
  }

  static Listing listingFromData(String id, Map<String, dynamic> data) {
    final photos = _strings(data['imageUrls']).isNotEmpty
        ? _strings(data['imageUrls'])
        : _strings(data['photoUrls']);
    final information = _stringMap(data['houseInformation']);
    if (_text(data['googleMapsUrl']).isNotEmpty) {
      information['Reference Map'] = data['googleMapsUrl'];
    }
    if (_text(data['distanceFromUniversity']).isNotEmpty) {
      information['Distance from University'] = data['distanceFromUniversity'];
    }
    return Listing(
      id: id,
      ownerId: _text(data['landownerId']),
      title: _text(data['propertyName']),
      address: _text(data['fullAddress']),
      price: _integer(data['monthlyRent']),
      image: photos.firstOrNull,
      photos: photos,
      amenities: _strings(data['amenities']),
      description: _text(data['description']),
      contact: _text(data['contactNumber']),
      availableRooms: _integer(data['availableRooms']),
      totalRooms: _integer(data['totalRooms']),
      available: data['status'] == 'Available',
      views: _integer(data['views']),
      latitude: _number(data['latitude']),
      longitude: _number(data['longitude']),
      billingInfo: _text(data['billingInfo']),
      houseInformation: information,
    );
  }

  static Map<String, dynamic> listingData(Listing listing) => {
    'listingId': listing.id,
    'landownerId': listing.ownerId,
    'propertyName': listing.title,
    'description': listing.description,
    'contactNumber': listing.contact,
    'monthlyRent': listing.price,
    'totalRooms': listing.totalRooms,
    'availableRooms': listing.availableRooms,
    'amenities': listing.amenities,
    'imageUrls': listing.photos,
    'fullAddress': listing.address,
    'distanceFromUniversity':
        listing.houseInformation['Distance from University'],
    'latitude': listing.latitude,
    'longitude': listing.longitude,
    'googleMapsUrl': listing.houseInformation['Reference Map'],
    'status': listing.available ? 'Available' : 'Unavailable',
    'billingInfo': listing.billingInfo,
    'houseInformation': listing.houseInformation,
  };

  Stream<List<Listing>> listings(UserProfile user) {
    Query<Map<String, dynamic>> query = db.collection('listings');
    if (user.role == UserRole.landlord) {
      query = query.where('landownerId', isEqualTo: user.id);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .where(
            (doc) =>
                user.role == UserRole.landlord ||
                doc.data()['status'] != 'Deleting',
          )
          .map((doc) => listingFromData(doc.id, doc.data()))
          .toList(),
    );
  }

  Stream<Set<String>> favorites(String userId) => db
      .collection('users')
      .doc(userId)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  Stream<List<PropertyReview>> reviews(String listingId) => db
      .collection('listings')
      .doc(listingId)
      .collection('reviews')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where(
              (doc) =>
                  _integer(doc.data()['rating']) >= 1 &&
                  _integer(doc.data()['rating']) <= 5,
            )
            .map((doc) {
              final data = doc.data();
              return PropertyReview(
                id: doc.id,
                listingId: listingId,
                boarderId: _text(data['boarderId']),
                boarderName: _text(data['boarderName']),
                rating: _integer(data['rating']),
                comment: _text(data['comment']),
                createdAt: data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0),
              );
            })
            .toList(),
      );

  Future<void> setFavorite(String listingId, bool selected) async {
    final ref = db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(listingId);
    if (selected) {
      await ref.set({
        'listingId': listingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Future<void> submitReview(
    String listingId,
    UserProfile user,
    int rating,
    String comment,
  ) async {
    if (uid != user.id || user.role != UserRole.boarder) {
      throw StateError('Sign in as a boarder to leave a review.');
    }
    final ref = db
        .collection('listings')
        .doc(listingId)
        .collection('reviews')
        .doc();
    await ref.set({
      'reviewId': ref.id,
      'listingId': listingId,
      'boarderId': uid,
      'boarderName': user.fullName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordView(String listingId) async {
    // Atomic increments; the rules permit only +1, never other listing changes.
    await db.collection('listings').doc(listingId).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<Listing> saveListing(Listing draft, {required bool creating}) async {
    final owner = uid;
    if (draft.ownerId != owner) {
      throw StateError('Please sign in as the listing owner.');
    }
    final ref = db.collection('listings').doc(draft.id);
    final existing = await ref.get(const GetOptions(source: Source.server));
    if (creating && existing.exists) {
      throw StateError('This listing has already been published.');
    }
    if (!creating &&
        (!existing.exists || existing.data()?['landownerId'] != owner)) {
      throw StateError('This listing is no longer available to edit.');
    }
    if (draft.photos.length > 4) {
      throw const FormatException('Choose at most 4 photos.');
    }
    final existingPhotos = _strings(existing.data()?['imageUrls']).isNotEmpty
        ? _strings(existing.data()?['imageUrls'])
        : _strings(existing.data()?['photoUrls']);
    if (draft.photos.any(
      (photo) =>
          SupabaseStorageService._isRemoteUrl(photo) &&
          !existingPhotos.contains(photo),
    )) {
      throw const FormatException(
        'Please select photos belonging to this listing.',
      );
    }
    var uploaded = <String>[];
    try {
      final photos = await _imageStorage.uploadListingImages(
        owner,
        draft.photos,
      );
      uploaded = photos
          .where((photo) => !draft.photos.contains(photo))
          .toList();
      final oldData = existing.data();
      final addressChanged =
          oldData != null && oldData['fullAddress'] != draft.address;
      LatLng? point = addressChanged
          ? null
          : PropertyLocationService.coordinates(
              draft.latitude,
              draft.longitude,
            );
      if (!addressChanged) {
        point ??= PropertyLocationService.coordinatesFromMapLink(
          draft.houseInformation['Reference Map'] ?? '',
        );
      }
      if (point == null) {
        try {
          point = await _location.resolve(draft.address, null, null);
        } catch (_) {
          /* Optional for old/address-only records. */
        }
      }
      final information = {...draft.houseInformation};
      if (addressChanged) information.remove('Reference Map');
      final data = listingData(draft.copyWith(photos: photos))
        ..['latitude'] = point?.latitude
        ..['longitude'] = point?.longitude
        ..['houseInformation'] = information
        ..['googleMapsUrl'] = information['Reference Map']
        ..['updatedAt'] = FieldValue.serverTimestamp();
      if (creating) {
        await ref.set({
          ...data,
          'views': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          ...data,
          // Remove the legacy key when an older listing is edited.
          'photoUrls': FieldValue.delete(),
        }); // Never overwrite views/reviews with a stale form.
      }
      await _imageStorage.deleteImages(
        existingPhotos.where((photo) => !photos.contains(photo)),
      );
      return listingFromData(draft.id, {
        ...data,
        'views': oldData?['views'] ?? 0,
      });
    } catch (error, stackTrace) {
      debugPrint('LISTING SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _imageStorage.deleteImages(uploaded);
      rethrow;
    }
  }

  Future<void> deleteListing(String listingId) async {
    final owner = uid;
    final ref = db.collection('listings').doc(listingId);
    final document = await ref.get(const GetOptions(source: Source.server));
    if (!document.exists) return;
    if (document.data()?['landownerId'] != owner) {
      throw StateError('Only the owner can delete this listing.');
    }
    // Keep the owner document until child cleanup finishes; failed cleanup can be retried.
    await ref.update({
      'status': 'Deleting',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final data = document.data();
    final photos = _strings(data?['imageUrls']).isNotEmpty
        ? _strings(data?['imageUrls'])
        : _strings(data?['photoUrls']);
    await _imageStorage.deleteImages(photos);
    while (true) {
      final children = await ref.collection('reviews').limit(400).get();
      if (children.docs.isEmpty) break;
      final batch = db.batch();
      for (final child in children.docs) {
        batch.delete(child.reference);
      }
      await batch.commit();
    }
    await ref.delete();
    // Favorites belong to other users; clients hide relationships to missing
    // listings and keep the private relationship harmlessly hidden until it is removed.
  }
}

Future<void> _synchronizeAuthenticatedRole(User user) async {
  // Supabase Storage authorization is handled by the storage-authorize Edge
  // Function, which verifies this Firebase token directly. Refresh here so a
  // newly registered/restored Firebase account always has a current token.
  await user.getIdToken(true);
}
