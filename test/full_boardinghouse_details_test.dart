import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stay_near/main.dart';
import 'package:stay_near/services/property_location.dart';

const _user = UserProfile(
  firstName: 'Maria',
  middleName: '',
  lastName: 'Cruz',
  email: 'maria@example.test',
  birthday: '',
  gender: '',
  contact: '',
  address: '',
  password: '',
  role: UserRole.boarder,
);

const _owner = UserProfile(
  firstName: 'Owen',
  middleName: '',
  lastName: 'Reyes',
  email: 'owner@example.test',
  birthday: '',
  gender: '',
  contact: '',
  address: '',
  password: '',
  role: UserRole.landlord,
);

Listing _property({
  String id = 'first',
  String title = 'Seaside Student House',
  String address = 'Clarin, Bohol',
  double? latitude,
  double? longitude,
  List<String> photos = const [],
  String? mapLink,
}) => Listing(
  id: id,
  title: title,
  address: address,
  price: 2400,
  image: null,
  photos: photos,
  latitude: latitude,
  longitude: longitude,
  availableRooms: 2,
  totalRooms: 5,
  billingInfo: 'Bills not included',
  contact: '09123456789',
  description: 'Quiet rooms for students with natural light. The full description from the owner is shown here.',
  amenities: [
    'Air Conditioning',
    'Refrigerator',
    'Private Bathroom',
    'CCTV',
    'Parking',
    'Laundry Area',
    'Study Table',
    'Wi-Fi',
  ],
  houseInformation: {
    'House rules': 'Quiet hours after 10 PM',
    'Landowner': 'Owen Reyes',
    'Distance from University': '160 meters',
    'Reference Map': ?mapLink,
  },
);

class _RoomPhotoPicker extends ProfilePhotoPicker {
  @override
  Future<String?> recover() async => null;
  @override
  Future<String?> pick(ImageSource source) async => 'assets/test-room.png';
}

class _Storage implements ReviewStorage {
  String data = '[]';
  bool failWrite = false;
  @override
  Future<List<PropertyReview>> read() async => (jsonDecode(data) as List)
      .map((item) => PropertyReview.fromJson(item as Map<String, dynamic>))
      .toList();
  @override
  Future<void> write(List<PropertyReview> reviews) async {
    if (failWrite) throw const FileSystemException('Storage unavailable');
    data = jsonEncode(reviews.map((review) => review.toJson()).toList());
  }
}

class _Location extends PropertyLocationService {
  final List<Uri> opened = [];
  int requests = 0;
  @override
  Future<LatLng> currentLocation() async {
    requests++;
    return const LatLng(9.96, 124.02);
  }

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class _GeolocationPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requested = LocationPermission.whileInUse;
  int permissionRequests = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission = requested;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    longitude: 124.02,
    latitude: 9.96,
    timestamp: DateTime.now(),
    accuracy: 3,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Future<void> _show(
  WidgetTester tester,
  ListingStore store,
  _Location location, {
  String id = 'first',
  Size size = const Size(390, 844),
  double scale = 1,
  VoidCallback? onBack,
  GlobalKey? captureKey,
  UserProfile user = _user,
  VoidCallback? onEdit,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: captureKey,
        child: ScreenFrame(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, child) => ListingPage(
              key: ValueKey(id),
              listing: store.byId(id)!,
              store: store,
              user: user,
              favorite: store.isFavorite(id),
              onFavorite: () => store.toggleFavorite(id),
              onBack: onBack ?? () {},
              onEdit: onEdit,
              locationService: location,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('landowner feedback is read-only, listing-specific and live', (
    tester,
  ) async {
    final storage = _Storage();
    final store = ListingStore(reviewStorage: storage)
      ..upsert(
        _property(mapLink: 'https://maps.google.com/?q=Clarin')
            .copyWith(ownerId: _owner.id),
      )
      ..upsert(
        _property(
          id: 'second',
          title: 'Second property',
          mapLink: 'https://maps.google.com/?q=9.95,124.02',
        ).copyWith(ownerId: _owner.id),
      );
    addTearDown(store.dispose);
    await store.submitReview(
      listingId: 'first',
      user: _user,
      rating: 5,
      comment: 'First property boarder feedback.',
    );
    await store.submitReview(
      listingId: 'second',
      user: _user,
      rating: 1,
      comment: 'Second property boarder feedback.',
    );
    final savedReviews = storage.data;
    final location = _Location();
    var backs = 0, edits = 0;
    await _show(
      tester,
      store,
      location,
      user: _owner,
      onBack: () => backs++,
      onEdit: () => edits++,
    );
    expect(find.text('Boarding House Details'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byKey(const ValueKey('submit-review')), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Leave a Review or Rating'), findsNothing);
    for (var star = 1; star <= 5; star++) {
      expect(find.byKey(ValueKey('review-star-$star')), findsNothing);
    }
    expect(find.text('First property boarder feedback.'), findsOneWidget);
    expect(find.text('Second property boarder feedback.'), findsNothing);
    expect(find.text('Maria Cruz'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('average-rating'))).data,
      '5.0',
    );
    expect(storage.data, savedReviews);
    await _tap(tester, find.byKey(const ValueKey('edit-listing-details')));
    expect(edits, 1);
    await _tap(tester, find.text('View on Google Maps'));
    expect(
      location.opened.single.toString(),
      'https://maps.google.com/?q=Clarin',
    );
    await store.submitReview(
      listingId: 'first',
      user: _user,
      rating: 3,
      comment: 'Another boarder review.',
    );
    await tester.pumpAndSettle();
    expect(find.text('Another boarder review.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('average-rating'))).data,
      '4.0',
    );
    expect(find.text('2 Reviews'), findsNWidgets(2));
    await expectLater(
      store.submitReview(
        listingId: 'first',
        user: _owner,
        rating: 5,
        comment: 'Owner attempt',
      ),
      throwsStateError,
    );
    expect(store.reviewsFor('first'), hasLength(2));
    expect(store.isFavorite('first'), isFalse);
    store.updateOwnedListing(
      store
          .byId('first')!
          .copyWith(
            title: 'Updated owner property',
            address: 'Updated full address',
            contact: '09990001111',
            description: 'Updated complete description.',
            available: false,
          ),
      _owner.id,
    );
    await tester.pumpAndSettle();
    expect(find.text('Updated owner property'), findsOneWidget);
    expect(find.text('Updated full address'), findsOneWidget);
    expect(find.text('Updated complete description.'), findsOneWidget);
    expect(find.text('09990001111'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('First property boarder feedback.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(backs, 1);
    await _show(tester, store, _Location(), id: 'second', user: _owner);
    expect(find.text('Second property'), findsOneWidget);
    expect(find.text('Second property boarder feedback.'), findsOneWidget);
    expect(find.text('First property boarder feedback.'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('average-rating'))).data,
      '1.0',
    );
    // The same widget responds to the authenticated role without changing data.
    await _show(tester, store, _Location(), id: 'second', user: _user);
    expect(find.byKey(const ValueKey('review-comment')), findsOneWidget);
    expect(find.byKey(const ValueKey('submit-review')), findsOneWidget);
    expect(
      find.textContaining('Landowner: Owen Reyes', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Reference Map:', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('https://maps.google.com', findRichText: true),
      findsNothing,
    );
    await _tap(tester, find.byTooltip('Add to Favorites'));
    expect(store.isFavorite('second'), isTrue);
    await _show(tester, store, _Location(), id: 'second', user: _owner);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byKey(const ValueKey('submit-review')), findsNothing);
    expect(store.isFavorite('second'), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'landowner empty feedback has no composer at text scale $scale',
      (tester) async {
        final store = ListingStore()
          ..upsert(_property().copyWith(ownerId: _owner.id));
        addTearDown(store.dispose);
        await _show(
          tester,
          store,
          _Location(),
          user: _owner,
          size: const Size(320, 568),
          scale: scale,
        );
        expect(find.text('No ratings yet'), findsOneWidget);
        expect(find.text('No reviews yet.'), findsOneWidget);
        expect(find.textContaining('Be the first'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.byKey(const ValueKey('submit-review')), findsNothing);
        expect(find.byTooltip('Add to Favorites'), findsNothing);
        await tester.ensureVisible(find.text('No reviews yet.'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'published owner contact, map pin and distance reach shared listing data',
    (tester) async {
      var step = 0;
      Listing? published;
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenFrame(
            child: StatefulBuilder(
              builder: (context, update) => RoomWizard(
                photoPicker: _RoomPhotoPicker(),
                step: step,
                onBack: () {},
                onProfile: () {},
                onNext: () => update(() => step++),
                onPrevious: () => update(() => step--),
                onPublish: (listing) => published = listing,
              ),
            ),
          ),
        ),
      );
      void fill(String hint, String value, {int index = 0}) {
        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .where(
              (field) =>
                  field.decoration?.hintText == hint &&
                  field.controller != null,
            );
        fields.elementAt(index).controller!.text = value;
      }

      fill('', 'Owner property');
      fill('', 'Full owner description', index: 1);
      fill('', '09123456789', index: 2);
      await _tap(tester, find.text('Next'));
      await _tap(tester, find.text('Photo 1'));
      await _tap(tester, find.text('Choose from Gallery'));
      await _tap(tester, find.text('Next'));
      fill('', '2400');
      final roomFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((field) => field.decoration?.hintText == '0')
          .toList();
      roomFields.first.controller!.text = '2';
      roomFields.last.controller!.text = '2';
      await _tap(tester, find.text('Next'));
      fill('Barangay, Municipality, City', 'Clarin, Bohol');
      fill('Enter distance information', '500 m from university');
      fill(
        'Paste a Google Maps link',
        'https://www.google.com/maps/@9.9621749,124.0246341,429m/data=!3m1!1e3?entry=ttu&g_ep=EgoyMDI2MDkxNi4wIKXMDSoASAFQAw%3D%3D',
      );
      await _tap(tester, find.text('Publish Listing'));
      expect(published!.contact, '09123456789');
      expect(published!.description, 'Full owner description');
      expect(
        published!.houseInformation['Distance from University'],
        '500 m from university',
      );
      expect(published!.latitude, 9.9621749);
      expect(published!.longitude, 124.0246341);
      expect(published!.availableRooms, 2);
      expect(published!.available, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'preferences adapter reloads written reviews through a new store instance',
    () async {
      final original = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = original);
      final first = ListingStore(reviewStorage: PreferencesReviewStorage())
        ..upsert(_property());
      addTearDown(first.dispose);
      await first.submitReview(
        listingId: 'first',
        user: _user,
        rating: 5,
        comment: 'Saved review',
      );
      final reopened = ListingStore(reviewStorage: PreferencesReviewStorage())
        ..upsert(_property());
      addTearDown(reopened.dispose);
      await reopened.loadReviews();
      expect(reopened.reviewsFor('first').single.comment, 'Saved review');
      expect(reopened.reviewsFor('first').single.boarderName, 'Maria Cruz');
      expect(reopened.byId('first')!.averageRating, 5);
    },
  );

  test('owner map links use property pins instead of camera coordinates', () {
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps?q=9.95,124.03',
      ),
      const LatLng(9.95, 124.03),
    );
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps/place/House/@10,125,15z/data=!3d9.95!4d124.03',
      ),
      const LatLng(9.95, 124.03),
    );
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps/@10,125,15z',
      ),
      const LatLng(10, 125),
    );
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps?ll=10,125',
      ),
      isNull,
    );
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://example.com/?q=9.95,124.03',
      ),
      isNull,
    );
  });

  testWidgets(
    'gallery opens selected photos, advances, and closes back to details',
    (tester) async {
      final store = ListingStore()
        ..upsert(_property(photos: ['data:invalid', 'data:second']));
      addTearDown(store.dispose);
      await _show(tester, store, _Location());
      await _tap(tester, find.text('1/2 Photos'));
      expect(find.byTooltip('Close photos'), findsOneWidget);
      await _tap(tester, find.byTooltip('Next photo'));
      expect(find.text('2/2 Photos'), findsOneWidget);
      await _tap(tester, find.byTooltip('Close photos'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ListingPage), findsOneWidget);
      expect(find.byTooltip('Close photos'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('reviews persist with property and account identity, update all summaries, and survive owner edits', () async {
    final storage = _Storage();
    final store = ListingStore(reviewStorage: storage);
    addTearDown(store.dispose);
    store.upsert(_property());
    store.upsert(_property(id: 'second'));
    store.toggleFavorite('first');
    for (final rating in [5, 4, 3]) {
      await store.submitReview(
        listingId: 'first',
        user: _user,
        rating: rating,
        comment: 'Review $rating',
      );
    }
    await store.submitReview(
      listingId: 'second',
      user: _user,
      rating: 1,
      comment: 'Second property',
    );
    final summary = ReviewSummary(store.reviewsFor('first'));
    expect(summary.average, 4);
    expect(summary.total, 3);
    expect(summary.counts, {1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
    expect(store.favorites.single.averageRating, 4);
    expect(
      store.reviewsFor('first').every((review) => review.boarderId == _user.id),
      isTrue,
    );
    store.upsert(_property(title: 'Edited house'));
    expect(store.favorites.single.reviewCount, 3);
    expect(store.favorites.single.title, 'Edited house');
    final restored = ListingStore(reviewStorage: storage)..upsert(_property());
    addTearDown(restored.dispose);
    await restored.loadReviews();
    expect(restored.reviewsFor('first'), hasLength(3));
    expect(restored.byId('first')!.averageRating, 4);
    expect(restored.reviewsFor('second').single.rating, 1);
  });

  test(
    'invalid input and failed saves do not create phantom reviews or ratings',
    () async {
      final storage = _Storage();
      final store = ListingStore(reviewStorage: storage)..upsert(_property());
      addTearDown(store.dispose);
      for (final rating in [0, 6]) {
        await expectLater(
          store.submitReview(
            listingId: 'first',
            user: _user,
            rating: rating,
            comment: 'Review',
          ),
          throwsArgumentError,
        );
      }
      await expectLater(
        store.submitReview(
          listingId: 'first',
          user: _user,
          rating: 5,
          comment: '  ',
        ),
        throwsArgumentError,
      );
      storage.failWrite = true;
      await expectLater(
        store.submitReview(
          listingId: 'first',
          user: _user,
          rating: 5,
          comment: 'Kept review',
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.reviewsFor('first'), isEmpty);
      expect(store.byId('first')!.reviewCount, 0);
      storage.failWrite = false;
      await store.submitReview(
        listingId: 'first',
        user: _user,
        rating: 5,
        comment: 'Kept review',
      );
      expect(store.reviewsFor('first'), hasLength(1));
    },
  );

  test(
    'coordinates and Maps links use the selected property as destination',
    () {
      expect(PropertyLocationService.coordinates(0, 0), const LatLng(0, 0));
      expect(PropertyLocationService.coordinates(91, 0), isNull);
      expect(PropertyLocationService.coordinates(double.nan, 0), isNull);
      expect(PropertyLocationService.coordinates(null, 124), isNull);
      final uri = PropertyLocationService.directionsUri(
        const LatLng(9.95, 124.03),
      );
      expect(uri.queryParameters.containsKey('origin'), isFalse);
      expect(uri.queryParameters['destination'], '9.95,124.03');
      expect(uri.queryParameters['travelmode'], 'driving');
      expect(
        PropertyLocationService.mapUri(
          null,
          'House & Rooms, Bohol',
        ).queryParameters['query'],
        'House & Rooms, Bohol',
      );
    },
  );

  test('location permissions are checked once per action and granted access is not requested again', () async {
    final original = GeolocatorPlatform.instance;
    final platform = _GeolocationPlatform();
    GeolocatorPlatform.instance = platform;
    addTearDown(() => GeolocatorPlatform.instance = original);
    final service = PropertyLocationService();
    expect(await service.currentLocation(), const LatLng(9.96, 124.02));
    expect(platform.permissionRequests, 0);
    platform.permission = LocationPermission.denied;
    await service.currentLocation();
    await service.currentLocation();
    expect(platform.permissionRequests, 1);
    for (final problem in [
      LocationProblem.denied,
      LocationProblem.deniedForever,
      LocationProblem.disabled,
    ]) {
      platform.enabled = problem != LocationProblem.disabled;
      platform.permission = problem == LocationProblem.deniedForever
          ? LocationPermission.deniedForever
          : LocationPermission.denied;
      platform.requested = LocationPermission.denied;
      await expectLater(
        service.currentLocation(),
        throwsA(
          isA<PropertyLocationException>().having(
            (error) => error.problem,
            'problem',
            problem,
          ),
        ),
      );
    }
  });

  testWidgets(
    'selected property updates live; favorites and system Back remain connected',
    (tester) async {
      final store = ListingStore()
        ..upsert(_property())
        ..upsert(_property(id: 'second', title: 'Another House'));
      addTearDown(store.dispose);
      final location = _Location();
      var backs = 0;
      await _show(tester, store, location, onBack: () => backs++);
      expect(find.text('Seaside Student House'), findsOneWidget);
      expect(find.text('Bills not included'), findsOneWidget);
      expect(
        find.textContaining('Quiet hours', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('09123456789'), findsOneWidget);
      expect(find.text('Refrigerator'), findsOneWidget);
      await _tap(tester, find.byTooltip('Add to Favorites'));
      expect(store.isFavorite('first'), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backs, 1);
      store.upsert(
        _property(title: 'Renamed House', address: 'Updated address'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Renamed House'), findsOneWidget);
      expect(find.text('Updated address'), findsOneWidget);
      await _show(tester, store, location, id: 'second');
      expect(find.text('Another House'), findsOneWidget);
      expect(find.text('Renamed House'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rating validation, failed-save recovery, immediate review display and form reset',
    (tester) async {
      final storage = _Storage();
      final store = ListingStore(reviewStorage: storage)..upsert(_property());
      addTearDown(store.dispose);
      await _show(tester, store, _Location());
      expect(find.text('Reviewing as Maria Cruz'), findsOneWidget);
      expect(find.text('Your Name'), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('submit-review')));
      expect(find.text('Please select a star rating.'), findsOneWidget);
      expect(find.text('Please write your review.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('review-star-4')));
      final comment = find.byKey(const ValueKey('review-comment'));
      await tester.ensureVisible(comment);
      await tester.enterText(comment, 'Clean rooms and reliable Wi-Fi.');
      storage.failWrite = true;
      await _tap(tester, find.byKey(const ValueKey('submit-review')));
      expect(store.reviewsFor('first'), isEmpty);
      expect(
        tester.widget<TextFormField>(comment).controller!.text,
        'Clean rooms and reliable Wi-Fi.',
      );
      storage.failWrite = false;
      await _tap(tester, find.byKey(const ValueKey('submit-review')));
      expect(store.reviewsFor('first').single.rating, 4);
      expect(find.text('Clean rooms and reliable Wi-Fi.'), findsOneWidget);
      expect(find.text('Maria Cruz'), findsOneWidget);
      expect(find.textContaining('Verified'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('average-rating'))).data,
        '4.0',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('rating-count-4'))).data,
        '1',
      );
      expect(tester.widget<TextFormField>(comment).controller!.text, isEmpty);
      expect(find.text('Select a rating'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Maps actions use exact coordinates and let Google Maps choose the origin',
    (tester) async {
      final store = ListingStore()
        ..upsert(
          _property(
            latitude: 9.95,
            longitude: 124.03,
            mapLink: 'https://www.google.com/maps/search/?api=1&query=Clarin%2C+Bohol',
          ),
        );
      addTearDown(store.dispose);
      final location = _Location();
      await _show(tester, store, location);
      expect(location.requests, 0);
      await _tap(tester, find.text('View on Google Maps'));
      expect(location.opened.single.queryParameters['query'], '9.95,124.03');
      await _tap(tester, find.text('Get Directions'));
      expect(
        location.opened.last.queryParameters.containsKey('origin'),
        isFalse,
      );
      expect(
        location.opened.last.queryParameters['destination'],
        '9.95,124.03',
      );
      expect(location.opened.last.queryParameters['travelmode'], 'driving');
      expect(location.requests, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing coordinates never open a fallback destination', (
    tester,
  ) async {
    final store = ListingStore()..upsert(_property());
    addTearDown(store.dispose);
    final location = _Location();
    await _show(tester, store, location);
    await _tap(tester, find.text('Get Directions'));
    expect(location.opened, isEmpty);
    expect(
      find.text(
        'The exact location for this boardinghouse is not available yet.',
      ),
      findsOneWidget,
    );
    expect(location.requests, 0);
  });

  testWidgets(
    'interactive map and directions use exact coordinates at 200 percent text size',
    (tester) async {
      final store = ListingStore()
        ..upsert(_property(latitude: 9.95, longitude: 124.03));
      addTearDown(store.dispose);
      final location = _Location();
      await _show(
        tester,
        store,
        location,
        size: const Size(320, 568),
        scale: 2,
      );
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter, const LatLng(9.95, 124.03));
      final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markers.markers.single.point, const LatLng(9.95, 124.03));
      await _tap(tester, find.text('Get Directions'));
      expect(
        location.opened.single.queryParameters['destination'],
        '9.95,124.03',
      );
      expect(
        location.opened.single.queryParameters.containsKey('origin'),
        isFalse,
      );
      expect(location.requests, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      '320px screen scrolls all content and handles keyboard at text scale $scale',
      (tester) async {
        final store = ListingStore()
          ..upsert(
            _property(
              title: 'A very long boarding house name for students',
              photos: ['data:invalid', 'data:also-invalid'],
            ),
          );
        addTearDown(store.dispose);
        await store.submitReview(
          listingId: 'first',
          user: _user,
          rating: 5,
          comment: 'A long review about the boarding house, the neighborhood and the facilities.',
        );
        await _show(
          tester,
          store,
          _Location(),
          size: const Size(320, 568),
          scale: scale,
        );
        expect(find.text('1/2 Photos'), findsOneWidget);
        await tester.dragFrom(
          tester.getTopLeft(find.byType(PageView)) + const Offset(260, 40),
          const Offset(-280, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('2/2 Photos'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('review-comment')),
        );
        await tester.showKeyboard(find.byKey(const ValueKey('review-comment')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('review-comment')),
          'Keyboard review',
        );
        await tester.ensureVisible(find.text('Maria Cruz'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('full screen visual preview', (tester) async {
    if (const bool.fromEnvironment('DETAILS_PREVIEW')) {
      // Optional local preview uses the SDK fonts, with no test-only app assets.
      final sdk = const String.fromEnvironment('FLUTTER_SDK');
      await tester.runAsync(() async {
        for (final entry in {
          'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf'],
          'MaterialIcons': ['materialicons-regular.otf'],
        }.entries) {
          final loader = FontLoader(entry.key);
          for (final name in entry.value) {
            loader.addFont(
              File('$sdk/bin/cache/artifacts/material_fonts/$name')
                  .readAsBytes()
                  .then((bytes) => ByteData.sublistView(bytes)),
            );
          }
          await loader.load();
        }
      });
    }
    final store = ListingStore()..upsert(_property());
    addTearDown(store.dispose);
    await store.submitReview(
      listingId: 'first',
      user: _user,
      rating: 5,
      comment:
          'Comfortable rooms, good ventilation and a quiet place to study.',
    );
    final key = GlobalKey();
    await _show(
      tester,
      store,
      _Location(),
      size: const Size(390, 2600),
      captureKey: key,
    );
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('DETAILS_PREVIEW')) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/details-preview.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
