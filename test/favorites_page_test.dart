import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_near/main.dart';

ListingStore _store() {
  final store = ListingStore();
  for (final listing in [
    Listing(
      id: 'jhes',
      title: 'Jhes BH',
      address: 'Poblacion Norte, Clarin, Bohol',
      price: 1200,
      image: null,
      availableRooms: 5,
      averageRating: 4.8,
      reviewCount: 24,
      description: 'Comfortable and affordable boardinghouse.',
      contact: '09261151787',
      amenities: ['WiFi', 'Air Conditioning', 'Study Desk', 'Shared Kitchen'],
    ),
    Listing(
      id: 'zafra',
      title: 'ZafraMar BH',
      address: 'Clarin, Bohol',
      price: 1200,
      image: null,
      amenities: ['WiFi', 'Parking'],
    ),
    Listing(
      id: 'ann',
      title: "AnnHath's Boardinghouse",
      address: 'Pob. Centro, Clarin, Bohol',
      price: 1500,
      image: null,
      amenities: ['Air Conditioning', 'Furnished'],
    ),
  ]) {
    store.upsert(listing);
  }
  store.toggleFavorite('jhes');
  store.toggleFavorite('ann');
  return store;
}

Future<void> _showFavorites(
  WidgetTester tester,
  ListingStore store, {
  Size size = const Size(390, 844),
  double scale = 1,
  ValueChanged<Listing>? onListing,
  VoidCallback? onHome,
  VoidCallback? onProfile,
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
      home: ScreenFrame(
        child: FavoritesPage(
          store: store,
          onListing: onListing ?? (_) {},
          onHome: onHome ?? () {},
          onProfile: onProfile ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _count(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('saved-properties-count')))
    .data!;

Future<void> _search(WidgetTester tester, String query) async {
  final field = find.byKey(const ValueKey('favorites-search'));
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      -250,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, query);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'saved count and search use favorites only, without changing saved data',
    (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      await _showFavorites(tester, store);
      expect(find.text('StayNear'), findsOneWidget);
      expect(find.text('Boarder'), findsOneWidget);
      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('Saved Properties'), findsOneWidget);
      expect(_count(tester), '2');
      expect(find.byKey(const ValueKey('property-zafra')), findsNothing);

      for (final query in [' jHeS ', 'POBLACION', 'wi-fi', 'affordable']) {
        await _search(tester, query);
        expect(
          find.byKey(const ValueKey('property-jhes')),
          findsOneWidget,
          reason: query,
        );
        expect(
          find.byKey(const ValueKey('property-ann')),
          findsNothing,
          reason: query,
        );
        expect(_count(tester), '2');
      }
      await _search(tester, 'Clarin');
      expect(find.byKey(const ValueKey('property-jhes')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('property-ann')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('property-ann')), findsOneWidget);
      await _search(tester, 'ZafraMar');
      expect(find.text('No matching favorites found'), findsOneWidget);
      expect(find.byKey(const ValueKey('property-zafra')), findsNothing);
      expect(_count(tester), '2');
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('favorites-search')))
            .controller!
            .text,
        isEmpty,
      );
      expect(store.favorites.map((listing) => listing.id), ['jhes', 'ann']);
      expect(store.allProperties, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removing the searched favorite updates total and empty states immediately',
    (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      Listing? opened;
      await _showFavorites(
        tester,
        store,
        onListing: (listing) => opened = listing,
      );
      await _search(tester, 'ann');
      await _tap(tester, find.byKey(const ValueKey('favorite-ann')));
      expect(opened, isNull, reason: 'Heart must not open Property Details');
      expect(store.isFavorite('ann'), isFalse);
      expect(_count(tester), '1');
      expect(find.text('No matching favorites found'), findsOneWidget);
      await _search(tester, '');
      await _tap(tester, find.byKey(const ValueKey('favorite-jhes')));
      expect(store.favorites, isEmpty);
      expect(_count(tester), '0');
      expect(find.text('No saved properties yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('favorites-search')), findsOneWidget);
      expect(find.text('StayNear').hitTestable(), findsOneWidget);
      expect(find.text('Favorites').hitTestable(), findsOneWidget);

      store.toggleFavorite('zafra');
      await tester.pumpAndSettle();
      expect(_count(tester), '1');
      await _tap(tester, find.byKey(const ValueKey('property-zafra')));
      expect(opened, same(store.byId('zafra')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner edits update saved information and reapply the active search',
    (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      await _showFavorites(tester, store);
      await _search(tester, 'WiFi');
      store.upsert(
        Listing(
          id: 'jhes',
          title: 'Updated House',
          address: 'New address',
          price: 3500,
          image: 'data:invalid',
          available: false,
          availableRooms: 5,
          description: 'Updated description',
          contact: '09123456789',
          amenities: ['Parking'],
          averageRating: 4.9,
          reviewCount: 32,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching favorites found'), findsOneWidget);
      expect(_count(tester), '2');
      await _search(tester, 'Updated');
      expect(find.text('Updated House'), findsOneWidget);
      expect(find.text('Updated description'), findsOneWidget);
      expect(find.text('New address'), findsOneWidget);
      expect(find.text('09123456789'), findsOneWidget);
      expect(find.text('Parking'), findsOneWidget);
      expect(find.text('UNAVAILABLE'), findsOneWidget);
      expect(find.text('0 Available'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('(32 reviews)'), findsOneWidget);
      expect(tester.widget<Photo>(find.byType(Photo)).url, 'data:invalid');
      expect(store.isFavorite('jhes'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'zero favorites retains the header, count, search and working navigation',
    (tester) async {
      final store = ListingStore();
      addTearDown(store.dispose);
      var homeTaps = 0;
      var profileTaps = 0;
      await _showFavorites(
        tester,
        store,
        onHome: () => homeTaps++,
        onProfile: () => profileTaps++,
      );
      expect(_count(tester), '0');
      expect(find.text('No saved properties yet'), findsOneWidget);
      await _search(tester, 'Jhes');
      expect(find.text('No saved properties yet'), findsOneWidget);
      await tester.tap(find.text('Search'));
      await tester.tap(find.text('Profile'));
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(homeTaps, 1);
      expect(profileTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiple saved properties scroll to the last card above navigation',
    (tester) async {
      final store = ListingStore();
      addTearDown(store.dispose);
      for (var index = 0; index < 12; index++) {
        store.upsert(
          Listing(
            id: 'saved-$index',
            title: 'Saved house $index',
            address: 'Clarin',
            price: 1000,
            image: null,
            amenities: ['WiFi', 'Study Desk'],
          ),
        );
        store.toggleFavorite('saved-$index');
      }
      await _showFavorites(tester, store);
      expect(_count(tester), '12');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('property-saved-11')),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      final cardBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('property-saved-11')))
          .dy;
      expect(
        cardBottom,
        lessThan(tester.getTopLeft(find.text('Favorites')).dy),
      );
      expect(find.text('Saved house 11').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'small phone wraps property text and amenities at text scale $scale',
      (tester) async {
        final store = ListingStore();
        addTearDown(store.dispose);
        store.upsert(
          Listing(
            id: 'long',
            title: "AnnHath's Long Boardinghouse Name",
            address: 'A very long address in Poblacion Norte, Clarin, Bohol',
            description: 'A comfortable boarding house with space for students to study and relax.',
            contact: '+63 926 115 1787 extension 12345',
            price: 1500,
            image: null,
            amenities: [
              'WiFi',
              'Air Conditioning',
              'Study Desk',
              'Shared Kitchen',
              'A longer amenity label that must wrap',
            ],
          ),
        );
        store.toggleFavorite('long');
        await _showFavorites(
          tester,
          store,
          size: const Size(320, 568),
          scale: scale,
        );
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1600),
        );
        await tester.pumpAndSettle();
        expect(find.text('Shared Kitchen'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _search(tester, 'Clarin');
        await tester.showKeyboard(
          find.byKey(const ValueKey('favorites-search')),
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(find.text('StayNear').hitTestable(), findsOneWidget);
        expect(find.text('Favorites').hitTestable(), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('favorites-search')),
          'missing',
        );
        await tester.pumpAndSettle();
        expect(_count(tester), '1');
        await tester.scrollUntilVisible(
          find.text('No matching favorites found'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('No matching favorites found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
