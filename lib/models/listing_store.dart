part of '../main.dart';

/// Shared in-memory listings and favorites, matching the app's session storage.
class ListingStore extends ChangeNotifier {
  ListingStore({Iterable<Listing> samples = const []})
    : _listings = {for (final listing in samples) listing.id: listing},
      _usingSamples = samples.isNotEmpty;

  final Map<String, Listing> _listings;
  final Set<String> _favoriteIds = {};
  bool _usingSamples;

  List<Listing> get allProperties => List.unmodifiable(_listings.values);
  List<Listing> get favorites => List.unmodifiable(
    _listings.values.where((listing) => isFavorite(listing.id)),
  );
  Listing? byId(String? id) => _listings[id];
  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (!_listings.containsKey(id)) return;
    if (!_favoriteIds.add(id)) _favoriteIds.remove(id);
    notifyListeners();
  }

  void upsert(Listing listing) {
    // Demo data is only used until the first real listing is published.
    if (_usingSamples) {
      _listings.clear();
      _favoriteIds.clear();
      _usingSamples = false;
    }
    _listings[listing.id] = listing;
    notifyListeners();
  }

  void remove(String id) {
    _listings.remove(id);
    _favoriteIds.remove(id);
    notifyListeners();
  }
}
