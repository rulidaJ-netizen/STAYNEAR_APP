import 'package:flutter_test/flutter_test.dart';
import 'package:stay_near/main.dart';

void main() {
  Listing listing({
    String? id,
    String title = 'Jhes BH',
    List<String> amenities = const [' Wi-Fi ', 'AIR CONDITIONING'],
  }) => Listing(
    id: id,
    title: title,
    address: 'Poblacion Norte, Clarin, Bohol',
    price: 1200,
    image: null,
    amenities: amenities,
    description: 'Quiet student rooms beside the university',
  );

  test(
    'search normalizes partial name, location, description and amenities',
    () {
      final property = listing();
      for (final query in [
        ' jHeS ',
        'CLARIN',
        'Poblacion',
        'student',
        'wifi',
        'Wi-Fi',
      ]) {
        expect(property.matches(query, {}), isTrue, reason: query);
      }
      expect(property.matches('missing', {}), isFalse);
      expect(property.matches('clarin', {'wifi', 'air conditioning'}), isTrue);
      expect(property.matches('clarin', {'wifi', 'parking'}), isFalse);
    },
  );

  test('favorites use stable IDs, reflect edits, and never duplicate', () {
    final store = ListingStore();
    addTearDown(store.dispose);
    final first = listing();
    final second = listing(title: 'ZafraMar BH');
    store.upsert(first);
    store.upsert(second);
    store.toggleFavorite(second.id);
    expect(store.favorites.single, same(second));
    expect(store.isFavorite(first.id), isFalse);
    final edited = listing(
      id: second.id,
      title: 'Updated BH',
      amenities: ['Parking'],
    );
    store.upsert(edited);
    expect(store.allProperties, hasLength(2));
    expect(store.favorites.single, same(edited));
    store.toggleFavorite(second.id);
    expect(store.favorites, isEmpty);
    store.toggleFavorite(second.id);
    store.toggleFavorite(second.id);
    store.toggleFavorite(second.id);
    expect(store.favorites, hasLength(1));
    store.remove(second.id);
    expect(store.favorites, isEmpty);
    expect(store.byId(second.id), isNull);
  });

  test(
    'real publishing replaces samples; filtering never mutates listings',
    () {
      final store = ListingStore(samples: [listing(id: 'sample')]);
      addTearDown(store.dispose);
      final real = listing(title: 'Owner listing');
      store.upsert(real);
      expect(store.allProperties.single, same(real));
      expect(
        store.allProperties.where((item) => item.matches('missing', {})),
        isEmpty,
      );
      expect(store.allProperties.single, same(real));
      expect(() => store.allProperties.clear(), throwsUnsupportedError);
      store.remove(real.id);
      expect(store.allProperties, isEmpty);
    },
  );
}
