import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_near/main.dart';
import 'package:stay_near/firebase_options.dart';
import 'package:stay_near/services/property_location.dart';
import 'package:latlong2/latlong.dart';

import 'support/firebase_test_backend.dart';

const owner = UserProfile(
  firstName: 'Owner',
  middleName: '',
  lastName: 'One',
  email: 'owner@example.test',
  birthday: '',
  gender: '',
  contact: '09123456789',
  address: 'Clarin',
  password: 'Password123!',
  role: UserRole.landlord,
);
const boarder = UserProfile(
  firstName: 'Boarder',
  middleName: '',
  lastName: 'One',
  email: 'boarder@example.test',
  birthday: '',
  gender: '',
  contact: '09123456789',
  address: 'Clarin',
  password: 'Password123!',
  role: UserRole.boarder,
);

Listing property(String uid, {String id = 'house-one', List<String>? photos}) =>
    Listing(
      id: id,
      ownerId: uid,
      title: 'Garden House',
      address: 'Clarin',
      price: 4000,
      image: null,
      photos: photos ?? [testPhoto],
      availableRooms: 2,
      totalRooms: 3,
      latitude: 9.96,
      longitude: 124.02,
      amenities: ['WiFi', 'Parking'],
      houseInformation: const {
        'Reference Map':
            'https://www.google.com/maps/search/?api=1&query=9.96,124.02',
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestFirebaseBackend backend;
  setUp(() => backend = TestFirebaseBackend());

  test('FlutterFire options target the StayNear project', () {
    expect(DefaultFirebaseOptions.web.projectId, 'staynear-58ae7');
    expect(DefaultFirebaseOptions.android.projectId, 'staynear-58ae7');
    expect(DefaultFirebaseOptions.ios.projectId, 'staynear-58ae7');
  });

  test('Firebase errors retain specific user-safe messages', () {
    expect(
      backendMessage(FirebaseAuthException(code: 'invalid-email')),
      'Please enter a valid email address.',
    );
    expect(
      backendMessage(FirebaseAuthException(code: 'invalid-credential')),
      'Invalid email or password.',
    );
    expect(
      backendMessage(FirebaseAuthException(code: 'email-already-in-use')),
      'This email is already registered. Please log in.',
    );
    expect(
      backendMessage(FirebaseAuthException(code: 'weak-password')),
      'Please use a password with at least 6 characters.',
    );
    expect(
      backendMessage(FirebaseAuthException(code: 'operation-not-allowed')),
      'Email/password sign-in is not enabled.',
    );
    expect(
      backendMessage(FirebaseAuthException(code: 'network-request-failed')),
      'Unable to connect to Firebase. Please check your internet connection.',
    );
    expect(
      backendMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      'You do not have permission to access this Firebase data.',
    );
  });

  test(
    'backend validates invalid email and weak password before Auth',
    () async {
      final invalidEmail = UserProfile(
        firstName: owner.firstName,
        middleName: owner.middleName,
        lastName: owner.lastName,
        email: 'invalid-email',
        birthday: owner.birthday,
        gender: owner.gender,
        contact: owner.contact,
        address: owner.address,
        password: owner.password,
        role: owner.role,
      );
      await expectLater(
        backend.register(invalidEmail),
        throwsA(isA<FirebaseAuthException>()),
      );
      final weak = UserProfile(
        firstName: owner.firstName,
        middleName: owner.middleName,
        lastName: owner.lastName,
        email: 'weak@example.test',
        birthday: owner.birthday,
        gender: owner.gender,
        contact: owner.contact,
        address: owner.address,
        password: '12345',
        role: owner.role,
      );
      await expectLater(
        backend.register(weak),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'weak-password',
          ),
        ),
      );
    },
  );

  test(
    'registration writes UID and role, no passwords; login loads stored role',
    () async {
      final registered = await backend.register(owner);
      expect(backend.auth.currentUser, isNull);
      final data =
          (await backend.db.collection('users').doc(registered.id).get())
              .data()!;
      expect(data['uid'], registered.id);
      expect(data['role'], 'landowner');
      expect(data['profilePhotoUrl'], isNull);
      expect(data.containsKey('password'), isFalse);
      expect(registered.password, isEmpty);
      expect(registered.profilePhoto, isNull);
      final login = await backend.login(owner.email, owner.password);
      expect(login.id, registered.id);
      expect(login.role, UserRole.landlord);
      await backend.auth.signOut();
      expect(
        () => backend.login(owner.email, 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    },
  );

  test('registration and login synchronize server claims before use', () async {
    final synchronizedUsers = <String>[];
    final claimsBackend = TestFirebaseBackend(
      synchronizeAuthClaims: (user) async {
        synchronizedUsers.add(user.uid);
      },
    );

    final registered = await claimsBackend.register(boarder);
    expect(synchronizedUsers, [registered.id]);

    await claimsBackend.login(boarder.email, boarder.password);
    expect(synchronizedUsers, [registered.id, registered.id]);
  });

  for (final draft in [boarder, owner]) {
    test('${draft.role.name} registration creates no profile image', () async {
      final registered = await backend.register(draft);
      final data =
          (await backend.db.collection('users').doc(registered.id).get())
              .data()!;
      expect(data['profilePhotoUrl'], isNull);
      expect(registered.profilePhoto, isNull);
      expect(
        backend.storage.paths.where(
          (path) => path.startsWith('profiles/${registered.id}/'),
        ),
        isEmpty,
      );
    });
  }

  test('empty stored profile photo is normalized to no photo', () {
    final profile = FirebaseBackend.profileFromData('uid', {
      ...FirebaseBackend.profileData(boarder),
      'profilePhotoUrl': '   ',
    });
    expect(profile.profilePhoto, isNull);
  });

  testWidgets('missing Boarder and Landowner photos use person icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            ProfileAvatar(source: null),
            LandownerProfileAvatar(source: ''),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.person), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
  });

  test('duplicate registration reports the Firebase Auth collision', () async {
    await backend.register(boarder);
    await expectLater(
      backend.register(boarder),
      throwsA(
        isA<FirebaseAuthException>().having(
          (error) => error.code,
          'code',
          'email-already-in-use',
        ),
      ),
    );
  });

  test('selected role must match the Firestore profile role', () async {
    await backend.register(boarder);
    await expectLater(
      backend.login(
        boarder.email,
        boarder.password,
        expectedRole: UserRole.landlord,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('registered as a Boarder'),
        ),
      ),
    );
    expect(backend.auth.currentUser, isNull);
    final profile = await backend.login(
      boarder.email,
      boarder.password,
      expectedRole: UserRole.boarder,
    );
    expect(profile.role, UserRole.boarder);
  });

  test(
    'missing users/{uid} gives a profile-specific error and signs out',
    () async {
      final registered = await backend.register(owner);
      await backend.db.collection('users').doc(registered.id).delete();
      await expectLater(
        backend.login(owner.email, owner.password),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('account profile is missing'),
          ),
        ),
      );
      expect(backend.auth.currentUser, isNull);
    },
  );

  test('forgot password uses Firebase Email/Password Auth', () async {
    await backend.register(boarder);
    await expectLater(backend.resetPassword(boarder.email), completes);
    await expectLater(
      backend.resetPassword('not-an-email'),
      throwsA(
        isA<FirebaseAuthException>().having(
          (error) => error.code,
          'code',
          'invalid-email',
        ),
      ),
    );
  });

  for (final draft in [boarder, owner]) {
    test(
      '${draft.role.name} profile uploads photo and survives repository recreation',
      () async {
        final user = await backend.signUpAndLogin(draft);
        final result = await backend.saveProfile(
          user.withProfileEdits(
            fullName: 'Saved Name',
            phone: '09991112222',
            email: user.email,
            address: 'Saved address',
            photo: testPhoto,
          ),
        );
        final photo = result.profile.profilePhoto!;
        expect(photo.startsWith('https://'), isTrue);
        expect(backend.storage.getData(photo), isNotEmpty);
        final reopened = FirebaseBackend(
          auth: backend.auth,
          firestore: backend.db,
          imageStorage: backend.storage,
        );
        final saved = await reopened.loadProfile();
        expect(saved.fullName, 'Saved Name');
        expect(saved.contact, '09991112222');
        expect(saved.profilePhoto, photo);
        expect(saved.password, isEmpty);
        final emailChange = await backend.saveProfile(
          saved.withProfileEdits(
            fullName: saved.fullName,
            phone: saved.contact,
            email: 'pending@example.test',
            address: saved.address,
          ),
        );
        expect(emailChange.emailVerificationSent, isTrue);
        expect((await reopened.loadProfile()).email, user.email);
      },
    );
  }

  test(
    'create/edit keep one document, upload and remove photos, retain views',
    () async {
      final user = await backend.signUpAndLogin(owner);
      final first = await backend.saveListing(
        property(user.id),
        creating: true,
      );
      expect(first.photos.single.startsWith('https://'), isTrue);
      expect(first.latitude, 9.96);
      expect(
        first.houseInformation.containsKey('Distance from University'),
        isFalse,
      );
      await backend.db.collection('listings').doc(first.id).update({
        'views': 7,
      });
      final edited = await backend.saveListing(
        first.copyWith(title: 'Edited', price: 5000, photos: [testPhoto]),
        creating: false,
      );
      expect(
        (await backend.db.collection('listings').get()).docs,
        hasLength(1),
      );
      expect(edited.id, first.id);
      expect(edited.views, 7);
      expect(edited.amenities, ['WiFi', 'Parking']);
      expect(edited.photos.single, isNot(first.photos.single));
      expect(backend.storage.getData(edited.photos.single), isNotEmpty);
      expect(
        () => backend.saveListing(property('another-owner'), creating: false),
        throwsStateError,
      );
    },
  );

  test(
    'published listing updates owner state immediately and reloads',
    () async {
      final user = await backend.signUpAndLogin(owner);
      final store = ListingStore(backend: backend)..bindUser(user);
      addTearDown(store.dispose);
      await store.publish(property(user.id, id: 'immediate-listing'));
      expect(store.forOwner(user.id), hasLength(1));
      expect(store.byId('immediate-listing')?.availableRooms, 2);

      final reloaded = ListingStore(backend: backend);
      addTearDown(reloaded.dispose);
      final loaded = Completer<void>();
      reloaded.addListener(() {
        if (reloaded.byId('immediate-listing') != null && !loaded.isCompleted) {
          loaded.complete();
        }
      });
      reloaded.bindUser(user);
      await loaded.future.timeout(const Duration(seconds: 2));
      expect(reloaded.forOwner(user.id), hasLength(1));
    },
  );

  test(
    'delete cleans its reviews/photos and preserves another listing',
    () async {
      final user = await backend.signUpAndLogin(owner);
      final first = await backend.saveListing(
        property(user.id),
        creating: true,
      );
      final second = await backend.saveListing(
        property(user.id, id: 'house-two'),
        creating: true,
      );
      await backend.db
          .collection('listings')
          .doc(first.id)
          .collection('reviews')
          .doc('r')
          .set({'rating': 5});
      await backend.deleteListing(first.id);
      expect(
        (await backend.db.collection('listings').doc(first.id).get()).exists,
        isFalse,
      );
      expect(
        (await backend.db
                .collection('listings')
                .doc(first.id)
                .collection('reviews')
                .get())
            .docs,
        isEmpty,
      );
      expect(
        (await backend.db.collection('listings').doc(second.id).get()).exists,
        isTrue,
      );
      expect(backend.storage.getData(second.photos.single), isNotEmpty);
    },
  );

  test('favorites/reviews persist, real ratings stream, sessions clear cached data', () async {
    final landowner = await backend.signUpAndLogin(owner);
    final listing = await backend.saveListing(
      property(landowner.id),
      creating: true,
    );
    await backend.auth.signOut();
    final user = await backend.signUpAndLogin(boarder);
    await backend.setFavorite(listing.id, true);
    await backend.submitReview(listing.id, user, 5, 'Quiet and clean');
    final store = ListingStore(backend: backend);
    addTearDown(store.dispose);
    store.bindUser(user);
    await Future<void>.delayed(Duration.zero);
    await store.loadReviews();
    expect(store.favorites.single.id, listing.id);
    expect(store.byId(listing.id)!.averageRating, 5);
    expect(store.reviewsFor(listing.id).single.boarderId, user.id);
    await backend.setFavorite(listing.id, false);
    await Future<void>.delayed(Duration.zero);
    expect(store.favorites, isEmpty);
    store.bindUser(null);
    expect(store.allProperties, isEmpty);
    expect(store.reviewsFor(listing.id), isEmpty);
    await backend.login(owner.email, owner.password);
    store.bindUser(landowner);
    await Future<void>.delayed(Duration.zero);
    await store.loadReviews();
    expect(store.byId(listing.id)!.reviewCount, 1);
    expect(
      () => backend.submitReview(listing.id, landowner, 1, 'Owner review'),
      throwsStateError,
    );
  });

  test(
    'missing optional Firestore fields are safe and ratings are not fabricated',
    () {
      final listing = FirebaseBackend.listingFromData('old', {
        'propertyName': 'Old house',
        'status': 'Available',
        'monthlyRent': 1000.0,
      });
      expect(listing.photos, isEmpty);
      expect(listing.amenities, isEmpty);
      expect(listing.latitude, isNull);
      expect(listing.averageRating, 0);
      expect(listing.price, 1000);
    },
  );

  test('GPS distance formats meters and kilometers without persisting it', () {
    expect(PropertyLocationService.formatDistance(999), '999 m');
    expect(PropertyLocationService.formatDistance(1000), '1.0 km');
    expect(PropertyLocationService.formatDistance(1567), '1.6 km');
    expect(
      PropertyLocationService.distanceBetween(
        const LatLng(0, 0),
        const LatLng(0, 0.01),
      ),
      closeTo(1113, 5),
    );
    expect(
      FirebaseBackend.listingData(property('uid'))
          .containsKey('boarderDistance'),
      isFalse,
    );
  });

  test('server timestamps and rejected photo paths protect data', () async {
    final user = await backend.signUpAndLogin(owner);
    final one = await backend.saveListing(property(user.id), creating: true);
    expect(
      (await backend.db.collection('listings').doc(one.id).get())
          .data()!['createdAt'],
      isA<Timestamp>(),
    );
    await expectLater(
      backend.saveListing(
        property(user.id, id: 'other', photos: one.photos),
        creating: true,
      ),
      throwsFormatException,
    );
    expect(
      (await backend.db.collection('listings').doc('other').get()).exists,
      isFalse,
    );
  });
}
