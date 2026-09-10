import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_near/main.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC',
);

class _Images extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageClient();
}

class _ImageClient extends Fake implements HttpClient {
  @override
  set autoUncompress(bool value) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest();
}

class _ImageRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _Headers();
  @override
  Future<HttpClientResponse> close() async => _ImageResponse();
}

class _Headers extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _png.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_png).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Listing> _properties() => [
  Listing(
    id: 'jhes',
    title: 'Jhes BH',
    address: 'Poblacion Norte, Clarin, Bohol',
    price: 1200,
    image: null,
    amenities: ['Wi-Fi', 'Air Conditioning'],
    availableRooms: 5,
    averageRating: 4.8,
    reviewCount: 24,
  ),
  Listing(
    id: 'zafra',
    title: 'ZafraMar BH',
    address: 'Clarin, Bohol',
    price: 1200,
    image: null,
    amenities: ['WiFi', 'Parking'],
    availableRooms: 2,
  ),
  Listing(
    id: 'ann',
    title: "AnnHath's Boardinghouse",
    address: 'Pob. Centro, Clarin, Bohol',
    price: 1500,
    image: null,
    amenities: ['Air Conditioning', 'Furnished'],
    availableRooms: 2,
  ),
];

Future<void> _showDashboard(
  WidgetTester tester,
  ListingStore store, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, width == 320 ? 568 : 844);
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
      home: ScreenFrame(
        child: BoarderDashboard(
          store: store,
          onListing: (_) {},
          onFavorites: () {},
          onProfile: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _mockFonts() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final asset = utf8.decode(message!.buffer.asUint8List());
    if (asset == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final weight in [
          'Thin',
          'ExtraLight',
          'Light',
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
          'Black',
        ])
          'PlusJakartaSans-$weight.ttf': [
            {'asset': 'PlusJakartaSans-$weight.ttf'},
          ],
      });
    }
    if (asset.endsWith('.ttf')) return ByteData(0);
    return null;
  });
  addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
}

Future<void> _login(WidgetTester tester, UserRole role) async {
  final auth = tester.widget<AuthPage>(find.byType(AuthPage));
  auth.onRegister(
    UserProfile(
      firstName: 'Test',
      middleName: '',
      lastName: 'User',
      email: 'test@example.test',
      birthday: '2000-01-01',
      gender: 'Male',
      contact: '09123456789',
      address: 'Clarin',
      password: 'Password123!',
      role: role,
    ),
  );
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<AuthPage>(find.byType(AuthPage))
        .onLogin('test@example.test', 'Password123!', role),
    isTrue,
  );
  await tester.pumpAndSettle();
  ScaffoldMessenger.of(tester.element(find.byType(ScreenFrame)))
      .clearSnackBars();
  await tester.pumpAndSettle();
}

Future<void> _logout(WidgetTester tester) async {
  tester.widget<ProfilePage>(find.byType(ProfilePage)).onLogout();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Yes'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    HttpOverrides.global = _Images();
  });
  tearDown(() {
    HttpOverrides.global = null;
  });

  testWidgets(
    'live search, combined amenities, count, clearing and empty results',
    (tester) async {
      final store = ListingStore(samples: _properties());
      addTearDown(store.dispose);
      await _showDashboard(tester, store);
      expect(find.text('StayNear'), findsOneWidget);
      expect(find.text('Boarder'), findsOneWidget);
      expect(find.text('3 properties found'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      final search = find.byKey(const ValueKey('boarder-search'));
      await tester.enterText(search, ' jHeS ');
      await tester.pumpAndSettle();
      expect(find.text('1 property found'), findsOneWidget);
      expect(
        tester
            .widget<BoarderListingCard>(find.byType(BoarderListingCard).first)
            .listing
            .id,
        'jhes',
      );
      await tester.enterText(search, 'Clarin');
      await tester.pumpAndSettle();
      expect(find.text('3 properties found'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const ValueKey('amenity-wifi')));
      expect(find.text('2 properties found'), findsOneWidget);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('amenity-air conditioning')),
      );
      expect(find.text('1 property found'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const ValueKey('amenity-wifi')));
      expect(find.text('2 properties found'), findsOneWidget);
      await _tapVisible(tester, find.text('Clear all filters'));
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('3 properties found'), findsOneWidget);
      await tester.enterText(search, 'no-such-property');
      await tester.pumpAndSettle();
      expect(find.text('0 properties found'), findsOneWidget);
      expect(find.text('No properties found'), findsOneWidget);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      expect(find.text('3 properties found'), findsOneWidget);
      expect(store.allProperties, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('scrolling and keyboard have no overflow at width $width', (
      tester,
    ) async {
      final store = ListingStore(samples: _properties());
      addTearDown(store.dispose);
      await _showDashboard(
        tester,
        store,
        width: width,
        scale: width == 320 ? 1.5 : 1,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('amenity-scroll')));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('amenity-furnished')),
        250,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('amenity-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('amenity-furnished')).hitTestable(),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('property-ann')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text("AnnHath's Boardinghouse"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2400));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const ValueKey('boarder-search')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('boarder-search')),
        'Clarin',
      );
      await tester.pumpAndSettle();
      expect(find.text('StayNear').hitTestable(), findsOneWidget);
      expect(find.text('Favorites').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('open dashboard reflects live owner edits and new amenities', (
    tester,
  ) async {
    final store = ListingStore();
    addTearDown(store.dispose);
    store.upsert(_properties().first);
    await _showDashboard(tester, store);
    await tester.enterText(
      find.byKey(const ValueKey('boarder-search')),
      'clarin',
    );
    await tester.pumpAndSettle();
    store.upsert(
      Listing(
        id: 'jhes',
        title: 'Renamed House',
        address: 'Bohol',
        price: 9000,
        image: null,
        amenities: ['Elevator'],
        availableRooms: 9,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 properties found'), findsOneWidget);
    await _tapVisible(tester, find.text('Clear all filters'));
    expect(find.text('Renamed House'), findsOneWidget);
    expect(find.text('9 Available'), findsOneWidget);
    expect(find.byKey(const ValueKey('amenity-elevator')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'images handle network, assets, local files, and missing sources',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('staynear-image-');
      final file = File('${directory.path}/listing.png');
      file.writeAsBytesSync(_png);
      addTearDown(() {
        file.deleteSync();
        directory.deleteSync();
      });
      await tester.runAsync(() async {
        for (final source in [
          null,
          'https://example.test/listing.png',
          file.path,
          file.uri.toString(),
          'assets/missing.png',
          'missing-file.png',
          'data:invalid',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: Photo(url: source, height: 180)),
            ),
          );
          await tester.pumpAndSettle();
          if (source == 'https://example.test/listing.png' ||
              source == file.path ||
              source == file.uri.toString()) {
            final image = tester.widget<Image>(find.byType(Image));
            await precacheImage(
              image.image,
              tester.element(find.byType(Photo)),
            );
            await tester.pumpAndSettle();
            expect(
              tester.widget<RawImage>(find.byType(RawImage)).image,
              isNotNull,
            );
          }
          expect(tester.takeException(), isNull, reason: source);
          expect(tester.getSize(find.byType(Photo)).height, 180);
        }
      });
    },
  );

  testWidgets('app routes synchronize favorites, exact details, and profile', (
    tester,
  ) async {
    _mockFonts();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const StayNearApp());
    await tester.pumpAndSettle();
    await _login(tester, UserRole.boarder);
    await tester.enterText(
      find.byKey(const ValueKey('boarder-search')),
      'Zafra',
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('favorite-sample-zaframar')),
    );
    expect(
      find.byType(ListingPage),
      findsNothing,
      reason: 'Heart must not open details',
    );
    expect(
      tester
          .widget<BoarderListingCard>(find.byType(BoarderListingCard))
          .favorite,
      isTrue,
    );
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('ZafraMar BH'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('property-sample-zaframar')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListingPage>(find.byType(ListingPage)).listing.id,
      'sample-zaframar',
    );
    tester.widget<ListingPage>(find.byType(ListingPage)).onBack();
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('favorite-sample-zaframar')));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('boarder-search')),
      'Zafra',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BoarderListingCard>(find.byType(BoarderListingCard))
          .favorite,
      isFalse,
    );
    await tester.enterText(
      find.byKey(const ValueKey('boarder-search')),
      'Jhes',
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('property-sample-jhes')),
    );
    expect(
      tester.widget<ListingPage>(find.byType(ListingPage)).listing.id,
      'sample-jhes',
    );
    tester.widget<ListingPage>(find.byType(ListingPage)).onBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    tester.widget<ProfilePage>(find.byType(ProfilePage)).onHome();
    await tester.pumpAndSettle();
    expect(find.byType(BoarderDashboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'published and edited owner listing reaches Search and Favorites',
    (tester) async {
      _mockFonts();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const StayNearApp());
      await tester.pumpAndSettle();
      await _login(tester, UserRole.landlord);
      tester
          .widget<LandlordDashboard>(find.byType(LandlordDashboard))
          .onAddRoom();
      await tester.pumpAndSettle();
      final property = Listing(
        title: 'Owner House',
        address: 'Clarin',
        price: 2500,
        image: null,
        amenities: ['WiFi', 'Parking'],
        description: 'Owner description',
        availableRooms: 4,
      );
      tester.widget<RoomWizard>(find.byType(RoomWizard)).onPublish(property);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Dialog))).pop();
      await tester.pumpAndSettle();
      tester.widget<LandlordDashboard>(find.byType(LandlordDashboard)).onEdit();
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      fields
              .firstWhere((field) => field.controller?.text == 'Owner House')
              .controller!
              .text =
          'Updated Owner House';
      fields
              .firstWhere((field) => field.controller?.text == 'PHP 2500')
              .controller!
              .text =
          'PHP 3,000';
      fields
              .firstWhere(
                (field) => field.controller?.text == 'Owner description',
              )
              .controller!
              .text =
          'Updated description';
      await _tapVisible(tester, find.text('Save'));
      tester
          .widget<LandlordDashboard>(find.byType(LandlordDashboard))
          .onProfile();
      await tester.pumpAndSettle();
      await _logout(tester);
      await _login(tester, UserRole.boarder);
      final dashboard = tester.widget<BoarderDashboard>(
        find.byType(BoarderDashboard),
      );
      expect(dashboard.store.allProperties, hasLength(1));
      final saved = dashboard.store.allProperties.single;
      expect(saved.id, property.id);
      expect(saved.title, 'Updated Owner House');
      expect(saved.price, 3000);
      expect(saved.description, 'Updated description');
      expect(saved.amenities, ['WiFi', 'Parking']);
      await _tapVisible(
        tester,
        find.byKey(ValueKey('favorite-${property.id}')),
      );
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Updated Owner House'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('property-${property.id}')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListingPage>(find.byType(ListingPage)).listing,
        same(saved),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
