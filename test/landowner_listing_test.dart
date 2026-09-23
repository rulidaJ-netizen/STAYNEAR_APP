import 'support/firebase_test_backend.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stay_near/main.dart';

const _photo =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC';
const _owner = UserProfile(
  firstName: 'Maria',
  middleName: '',
  lastName: 'Cruz',
  email: 'owner@example.test',
  birthday: '',
  gender: '',
  contact: '09998887777',
  address: 'Clarin',
  password: 'password',
  role: UserRole.landlord,
);

Listing _listing({String id = 'a', String? ownerId, bool available = true}) =>
    Listing(
      id: id,
      ownerId: ownerId ?? _owner.id,
      title: 'Garden House $id',
      address: 'North Road, Clarin',
      price: 2750,
      image: null,
      availableRooms: 3,
      totalRooms: 7,
      views: 19,
      available: available,
      averageRating: 4.5,
      reviewCount: 2,
      contact: '09998887777',
      description: 'Quiet rooms with a garden and a shared study area.',
      amenities: ['WiFi', 'Parking'],
      latitude: 9.95,
      longitude: 124.02,
      billingInfo: 'Utilities billed separately',
      houseInformation: {
        'Reference Map': 'https://maps.google.com/?q=9.95,124.02',
        'Distance from University': '800 m',
      },
    );

class _Picker extends ProfilePhotoPicker {
  String? result = _photo.replaceFirst(
    'image/png;',
    'image/png;name=replacement;',
  );
  bool fail = false;
  @override
  Future<String?> recover() async => null;
  @override
  Future<String?> pick(ImageSource source) async {
    if (fail) throw PlatformException(code: 'photo_access_denied');
    return result;
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.byKey(ValueKey('edit-$label'));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _editor(
  WidgetTester tester,
  Listing listing, {
  FutureOr<void> Function(Listing)? onSave,
  VoidCallback? onBack,
  ProfilePhotoPicker? picker,
  double scale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: ScreenFrame(
        child: EditListingPage(
          listing: listing,
          onBack: onBack ?? () {},
          onProfile: () {},
          onSave: onSave ?? (_) {},
          photoPicker: picker ?? _Picker(),
        ),
      ),
    ),
  ),
);

void _mockFonts() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final weight in [
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
        ])
          'google_fonts/PlusJakartaSans-$weight.ttf': [
            {'asset': 'google_fonts/PlusJakartaSans-$weight.ttf'},
          ],
      });
    }
    if (key.endsWith('.ttf')) return ByteData(0);
    if (key.endsWith('.png')) {
      return ByteData.sublistView(Uri.parse(_photo).data!.contentAsBytes());
    }
    return null;
  });
  addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'ownership and saved edits preserve other listings and live property data',
    () {
      final store = ListingStore();
      addTearDown(store.dispose);
      final first = _listing();
      final second = _listing(id: 'b');
      final foreign = _listing(id: 'foreign', ownerId: 'another-owner');
      for (final listing in [first, second, foreign]) {
        store.upsert(listing);
      }
      expect(store.forOwner(_owner.id).map((item) => item.id), ['a', 'b']);
      expect(store.forOwner(null), isEmpty);
      final draft = first.copyWith(
        title: 'Edited garden',
        photos: [_photo],
        available: false,
      );
      store.upsert(first.withRating(4.8, 3));
      store.updateOwnedListing(draft, _owner.id);
      final saved = store.byId(first.id)!;
      expect(saved.title, 'Edited garden');
      expect(saved.image, _photo);
      expect(saved.ownerId, _owner.id);
      expect(saved.averageRating, 4.8);
      expect(saved.reviewCount, 3);
      expect(saved.views, first.views);
      expect(saved.totalRooms, first.totalRooms);
      expect(saved.latitude, first.latitude);
      expect(saved.longitude, first.longitude);
      expect(saved.houseInformation, first.houseInformation);
      expect(saved.billingInfo, first.billingInfo);
      expect(saved.amenities, first.amenities);
      final withoutPhotos = saved.copyWith(photos: []);
      expect(withoutPhotos.image, isNull);
      expect(withoutPhotos.photos, isEmpty);
      expect(store.byId(second.id), same(second));
      expect(
        () => store.updateOwnedListing(foreign, _owner.id),
        throwsStateError,
      );
      store.remove(first.id);
      expect(
        () => store.updateOwnedListing(draft, _owner.id),
        throwsStateError,
      );
      expect(store.forOwner(_owner.id).single, same(second));
    },
  );

  testWidgets('dashboard aggregates owned listings and isolates card actions', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final store = ListingStore();
    addTearDown(store.dispose);
    final first = _listing(), second = _listing(id: 'b', available: false);
    for (final item in [
      first,
      second,
      _listing(id: 'foreign', ownerId: 'elsewhere'),
    ]) {
      store.upsert(item);
    }
    final opened = <String>[], edited = <String>[], deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenFrame(
          child: LandlordDashboard(
            store: store,
            ownerId: _owner.id,
            onListing: (item) => opened.add(item.id),
            onEdit: (item) => edited.add(item.id),
            onDelete: (item) => deleted.add(item.id),
            onAddRoom: () {},
            onProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Map<String, String> stats() => {
      for (final stat in tester.widgetList<StatCard>(find.byType(StatCard)))
        stat.label: stat.number,
    };
    expect(stats(), {
      'Total Listings': '2',
      'Available Rooms': '3',
      'Total Views': '38',
      'Active Listings': '1',
    });
    await _tap(tester, find.text(first.title));
    expect(opened, ['a']);
    final card = find.byKey(const ValueKey('owner-listing-a'));
    await _tap(tester, find.descendant(of: card, matching: find.text('Edit')));
    await _tap(
      tester,
      find.descendant(of: card, matching: find.text('Delete')),
    );
    expect(edited, ['a']);
    expect(deleted, ['a']);
    expect(opened, ['a']);
    store.updateOwnedListing(
      first.copyWith(available: false, availableRooms: 1),
      _owner.id,
    );
    store.remove(second.id);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(stats(), {
      'Total Listings': '1',
      'Available Rooms': '0',
      'Total Views': '19',
      'Active Listings': '0',
    });
    expect(find.text('Garden House foreign'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'save commits every form value and photo to the same shared record',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final store = ListingStore();
      addTearDown(store.dispose);
      final original = _listing().copyWith(photos: [_photo]);
      store.upsert(original);
      await _editor(
        tester,
        original,
        onSave: (draft) => store.updateOwnedListing(draft, _owner.id),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Remove Photo 1'));
      await _tap(tester, find.text('Photo 2'));
      await _tap(tester, find.text('Choose from Gallery'));
      expect(store.byId(original.id), same(original));
      await _tap(tester, find.text('Unavailable'));
      await _enter(tester, 'Property Name', 'Updated garden');
      await _enter(tester, 'Monthly Price', 'PHP 12,345');
      await _enter(tester, 'Available Rooms', '2');
      await _enter(tester, 'Location', 'South Road, Clarin');
      await _enter(tester, 'Contact Number', '09121112222');
      await _enter(tester, 'Description', 'A completely updated description.');
      await _tap(tester, find.text('Save'));
      final saved = store.byId(original.id)!;
      expect(saved.title, 'Updated garden');
      expect(saved.price, 12345);
      expect(saved.availableRooms, 2);
      expect(saved.available, isFalse);
      expect(saved.address, 'South Road, Clarin');
      expect(saved.contact, '09121112222');
      expect(saved.description, 'A completely updated description.');
      expect(saved.photos, [
        _photo.replaceFirst('image/png;', 'image/png;name=replacement;'),
      ]);
      expect(saved.image, isNot(original.image));
      expect(saved.houseInformation, original.houseInformation);
      expect(saved.latitude, original.latitude);
      expect(saved.totalRooms, original.totalRooms);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel discards text, status and removed photos; picker errors retain draft',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final original = _listing().copyWith(photos: [_photo]);
      final picker = _Picker()..fail = true;
      var saves = 0, cancelled = 0;
      await _editor(
        tester,
        original,
        picker: picker,
        onSave: (_) => saves++,
        onBack: () => cancelled++,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Remove Photo 1'));
      await _tap(tester, find.text('Photo 1'));
      await _tap(tester, find.text('Choose from Gallery'));
      expect(
        find.textContaining('Could not access your photos'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Unavailable'));
      await _enter(tester, 'Property Name', 'Unsaved name');
      await _tap(tester, find.text('Cancel'));
      expect(cancelled, 1);
      expect(saves, 0);
      expect(original.title, 'Garden House a');
      expect(original.available, isTrue);
      expect(original.photos, [_photo]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'validation rejects invalid prices and room counts; failed save allows retry',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      var saves = 0;
      await _editor(
        tester,
        _listing(),
        onSave: (_) {
          saves++;
          throw StateError('save failed');
        },
      );
      await tester.pumpAndSettle();
      for (final invalid in ['-50', '1.50', 'abc', 'PHP 1,2', '0']) {
        await _enter(tester, 'Monthly Price', invalid);
        await _tap(tester, find.text('Save'));
        expect(saves, 0);
      }
      await _enter(tester, 'Monthly Price', '3000');
      for (final invalid in ['-1', '8', '1.5', 'abc']) {
        await _enter(tester, 'Available Rooms', invalid);
        await _tap(tester, find.text('Save'));
        expect(saves, 0);
      }
      await _enter(tester, 'Available Rooms', '0');
      await _tap(tester, find.text('Save'));
      expect(saves, 1);
      expect(
        find.textContaining('Your changes are still here'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Save'));
      expect(saves, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty dashboard separates its message from the add button', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final store = ListingStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenFrame(
          child: LandlordDashboard(
            store: store,
            ownerId: _owner.id,
            onListing: (_) {},
            onEdit: (_) {},
            onDelete: (_) {},
            onAddRoom: () {},
            onProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final message = find.text('Add new room to publish your new listing.');
    final button = find.widgetWithText(FilledButton, 'Add New Room');
    expect(message, findsOneWidget);
    expect(button, findsOneWidget);
    expect(
      tester.getTopLeft(button).dy - tester.getBottomLeft(message).dy,
      greaterThanOrEqualTo(20),
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 900),
  ]) {
    testWidgets('dashboard and editor scroll without overflow at $size', (
      tester,
    ) async {
      _viewport(tester, size);
      final store = ListingStore()
        ..upsert(
          _listing().copyWith(
            title: 'A long property name that should wrap across several lines',
            address: 'A long street address in a barangay near the university in Clarin, Bohol',
          ),
        );
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: ScreenFrame(
              child: LandlordDashboard(
                store: store,
                ownerId: _owner.id,
                onListing: (_) {},
                onEdit: (_) {},
                onDelete: (_) {},
                onAddRoom: () {},
                onProfile: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Add New Room'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await _editor(tester, _listing(), scale: 1.8);
      await tester.pumpAndSettle();
      await _enter(
        tester,
        'Description',
        'A full description with large text.',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Cancel'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'actual app routes the selected listing, saves, cancels and deletes independently',
    (tester) async {
      _mockFonts();
      const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(pickerChannel, (_) async => null);
      addTearDown(
        () => messenger.setMockMethodCallHandler(pickerChannel, null),
      );
      _viewport(tester, const Size(390, 844));
      final backend = TestFirebaseBackend();
      await tester.pumpWidget(StayNearApp(backend: backend));
      await tester.widget<AuthPage>(find.byType(AuthPage)).onRegister(_owner);
      await tester.pumpAndSettle();
      expect(
        await tester
            .widget<AuthPage>(find.byType(AuthPage))
            .onLogin(_owner.email, _owner.password, _owner.role),
        isTrue,
      );
      await tester.pumpAndSettle();
      LandlordDashboard dashboard() =>
          tester.widget<LandlordDashboard>(find.byType(LandlordDashboard));
      ScaffoldMessenger.of(tester.element(find.byType(ScreenFrame)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      for (final id in ['a', 'b']) {
        dashboard().onAddRoom();
        await tester.pumpAndSettle();
        final wizard = tester.widget<RoomWizard>(find.byType(RoomWizard));
        await wizard.onPublish(_listing(id: id).copyWith(photos: [testPhoto]));
        wizard.onPublished!();
        await tester.pumpAndSettle();
      }
      final store = dashboard().store;
      expect(store.forOwner(backend.uid), hasLength(2));
      dashboard().onEdit(store.byId('b')!);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditListingPage>(find.byType(EditListingPage)).listing.id,
        'b',
      );
      await _enter(tester, 'Property Name', 'Saved second house');
      await _tap(tester, find.text('Save'));
      expect(store.byId('a')!.title, 'Garden House a');
      expect(store.byId('b')!.title, 'Saved second house');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('owner-listing-b')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(tester, find.text('Saved second house'));
      await tester.pumpAndSettle();
      final details = tester.widget<ListingPage>(find.byType(ListingPage));
      expect(details.listing, same(store.byId('b')));
      expect(details.listing.title, 'Saved second house');
      expect(details.onFavorite, isNull);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byKey(const ValueKey('review-comment')), findsNothing);
      expect(find.byKey(const ValueKey('submit-review')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('edit-listing-details')));
      expect(
        tester.widget<EditListingPage>(find.byType(EditListingPage)).listing.id,
        'b',
      );
      await _enter(tester, 'Monthly Price', '3200');
      await _enter(tester, 'Description', 'Updated from Details');
      await _tap(tester, find.text('Save'));
      expect(find.byType(ListingPage), findsOneWidget);
      final updatedDetails = tester.widget<ListingPage>(
        find.byType(ListingPage),
      );
      expect(updatedDetails.listing.id, 'b');
      expect(updatedDetails.listing.price, 3200);
      expect(updatedDetails.listing.description, 'Updated from Details');
      expect(store.byId('a')!.price, 2750);
      await _tap(tester, find.byKey(const ValueKey('edit-listing-details')));
      await _enter(tester, 'Property Name', 'Discard the details draft');
      await _tap(tester, find.text('Cancel'));
      expect(find.byType(ListingPage), findsOneWidget);
      expect(store.byId('b')!.title, 'Saved second house');
      tester.widget<ListingPage>(find.byType(ListingPage)).onBack();
      await tester.pumpAndSettle();
      dashboard().onEdit(store.byId('b')!);
      await tester.pumpAndSettle();
      await _enter(tester, 'Property Name', 'Discard this edit');
      await _tap(tester, find.text('Cancel'));
      expect(store.byId('b')!.title, 'Saved second house');
      dashboard().onDelete(store.byId('b')!);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')),
      );
      await tester.pumpAndSettle();
      expect(store.byId('b'), isNotNull);
      dashboard().onDelete(store.byId('b')!);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();
      expect(store.byId('b'), isNull);
      expect(store.byId('a'), isNotNull);
      dashboard().onProfile();
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional landowner visual previews', (tester) async {
    if (!const bool.fromEnvironment('LANDOWNER_PREVIEW')) return;
    await tester.runAsync(() async {
      const sdk = String.fromEnvironment('FLUTTER_SDK');
      for (final entry in {
        'Roboto': [
          'roboto-regular.ttf',
          'roboto-medium.ttf',
          'roboto-bold.ttf',
        ],
        'MaterialIcons': ['materialicons-regular.otf'],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final file in entry.value) {
          loader.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/$file')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await loader.load();
      }
    });
    _viewport(tester, const Size(390, 1480));
    final listing = _listing();
    final store = ListingStore()..upsert(listing);
    addTearDown(store.dispose);
    for (final editor in [false, true]) {
      await tester.pumpWidget(const SizedBox());
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: capture,
            child: ScreenFrame(
              child: editor
                  ? EditListingPage(
                      listing: listing,
                      onBack: () {},
                      onProfile: () {},
                      onSave: (_) {},
                      photoPicker: _Picker(),
                    )
                  : LandlordDashboard(
                      store: store,
                      ownerId: _owner.id,
                      onListing: (_) {},
                      onEdit: (_) {},
                      onDelete: (_) {},
                      onAddRoom: () {},
                      onProfile: () {},
                    ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/landowner-${editor ? 'edit' : 'dashboard'}-preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
