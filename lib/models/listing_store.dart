part of '../main.dart';

/// Firebase streams feed the existing notifier. Unconnected stores support
/// isolated widget tests; app startup always supplies the Firebase backend.
class ListingStore extends ChangeNotifier {
  ListingStore({
    Iterable<Listing> samples = const [],
    this.reviewStorage,
    this.backend,
    this.onError,
  }) : _listings = {for (final listing in samples) listing.id: listing},
       _usingSamples = samples.isNotEmpty;

  final Map<String, Listing> _listings;
  final Set<String> _favoriteIds = {};
  bool _usingSamples;
  final ReviewStorage? reviewStorage;
  List<PropertyReview> _reviews = [];
  Future<void>? _loadingReviews;
  bool _reviewsLoaded = false;
  bool _savingReview = false;
  bool _disposed = false;
  final FirebaseBackend? backend;
  final void Function(Object)? onError;
  StreamSubscription<List<Listing>>? _listingSubscription;
  StreamSubscription<Set<String>>? _favoriteSubscription;
  final Map<String, StreamSubscription<List<PropertyReview>>>
  _reviewSubscriptions = {};
  final Map<String, Completer<void>> _reviewReady = {};
  final Set<String> _pendingFavorites = {}, _pendingListings = {}, _viewed = {};
  UserProfile? _user;
  int _session = 0;

  void bindUser(UserProfile? user) {
    final session = ++_session;
    _listingSubscription?.cancel();
    _favoriteSubscription?.cancel();
    for (final subscription in _reviewSubscriptions.values) {
      subscription.cancel();
    }
    _reviewSubscriptions.clear();
    for (final ready in _reviewReady.values) {
      if (!ready.isCompleted) ready.complete();
    }
    _reviewReady.clear();
    _listings.clear();
    _favoriteIds.clear();
    _reviews.clear();
    _viewed.clear();
    _pendingFavorites.clear();
    _pendingListings.clear();
    _user = user;
    if (!_disposed) notifyListeners();
    final service = backend;
    if (user == null || service == null) return;
    _listingSubscription = service
        .listings(user)
        .listen(
          (listings) {
            if (_disposed || session != _session) return;
            _listings
              ..clear()
              ..addEntries(
                listings.map((listing) => MapEntry(listing.id, listing)),
              );
            final removed = _reviewSubscriptions.keys
                .where((id) => !_listings.containsKey(id))
                .toList();
            for (final id in removed) {
              _reviewSubscriptions.remove(id)?.cancel();
              final ready = _reviewReady.remove(id);
              if (ready != null && !ready.isCompleted) ready.complete();
              _reviews.removeWhere((review) => review.listingId == id);
            }
            for (final listing in listings) {
              if (!_reviewSubscriptions.containsKey(listing.id)) {
                _reviewReady[listing.id] = Completer<void>();
                _reviewSubscriptions[listing.id] = service
                    .reviews(listing.id)
                    .listen(
                      (reviews) {
                        if (_disposed || session != _session) return;
                        _reviews.removeWhere(
                          (review) => review.listingId == listing.id,
                        );
                        _reviews.addAll(reviews);
                        _refreshRating(listing.id);
                        final ready = _reviewReady[listing.id];
                        if (ready != null && !ready.isCompleted) {
                          ready.complete();
                        }
                        notifyListeners();
                      },
                      onError: (Object error) {
                        if (session != _session || _disposed) return;
                        final ready = _reviewReady[listing.id];
                        if (ready != null && !ready.isCompleted) {
                          ready.complete();
                        }
                        onError?.call(error);
                      },
                    );
              }
              _refreshRating(listing.id);
            }
            notifyListeners();
          },
          onError: (Object error) {
            if (session == _session && !_disposed) onError?.call(error);
          },
        );
    if (user.role == UserRole.boarder) {
      _favoriteSubscription = service
          .favorites(user.id)
          .listen(
            (ids) {
              if (_disposed || session != _session) return;
              _favoriteIds
                ..clear()
                ..addAll(ids);
              notifyListeners();
            },
            onError: (Object error) {
              if (session == _session && !_disposed) onError?.call(error);
            },
          );
    }
  }

  Future<void> publish(Listing listing) async {
    if (backend == null) {
      upsert(listing);
      return;
    }
    if (!_pendingListings.add(listing.id)) {
      throw StateError('This listing is already being saved.');
    }
    try {
      final session = _session;
      final saved = await backend!.saveListing(listing, creating: true);
      if (session == _session && !_disposed) upsert(saved);
    } finally {
      _pendingListings.remove(listing.id);
    }
  }

  Future<void> deleteOwned(String id) async {
    if (backend == null) {
      remove(id);
      return;
    }
    if (!_pendingListings.add(id)) return;
    try {
      final session = _session;
      await backend!.deleteListing(id);
      if (session == _session && !_disposed) remove(id);
    } finally {
      _pendingListings.remove(id);
    }
  }

  void recordView(String id) {
    if (backend == null || _user?.role != UserRole.boarder || !_viewed.add(id)) {
      return;
    }
    final session = _session;
    backend!.recordView(id).catchError((Object error) {
      if (session != _session || _disposed) return;
      _viewed.remove(id);
      onError?.call(error);
    });
  }

  List<PropertyReview> reviewsFor(String id) => List.unmodifiable(
    _reviews.where((review) => review.listingId == id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  Future<void> loadReviews() {
    if (backend != null) {
      return Future.wait(_reviewReady.values.map((ready) => ready.future))
          .then((_) {});
    }
    if (_reviewsLoaded) return Future.value();
    return _loadingReviews ??= _readReviews();
  }

  Future<void> _readReviews() async {
    try {
      _reviews = await reviewStorage?.read() ?? [];
      _reviewsLoaded = true;
      for (final id in _reviews.map((review) => review.listingId).toSet()) {
        _refreshRating(id);
      }
      if (!_disposed) notifyListeners();
    } finally {
      _loadingReviews = null;
    }
  }

  Future<void> submitReview({
    required String listingId,
    required UserProfile user,
    required int rating,
    required String comment,
    String? displayName,
  }) async {
    if (user.role != UserRole.boarder || user.email.trim().isEmpty) {
      throw StateError('Sign in as a boarder to leave a review.');
    }
    final name = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : (displayName ?? '').trim();
    if (rating < 1 || rating > 5 || comment.trim().isEmpty || name.isEmpty) {
      throw ArgumentError('Choose a rating and enter your name and review.');
    }
    if (_savingReview) throw StateError('A review is already being saved.');
    _savingReview = true;
    try {
      if (backend != null) {
        await backend!.submitReview(listingId, user, rating, comment);
        return;
      }
      await loadReviews();
      if (!_listings.containsKey(listingId)) {
        throw StateError('This property is no longer available.');
      }
      final now = DateTime.now();
      final review = PropertyReview(
        id: 'review-${now.microsecondsSinceEpoch}',
        listingId: listingId,
        boarderId: user.id,
        boarderName: name,
        rating: rating,
        comment: comment.trim(),
        createdAt: now,
      );
      final updated = [..._reviews, review];
      await reviewStorage?.write(updated);
      _reviews = updated;
      _refreshRating(listingId);
      if (!_disposed) notifyListeners();
    } finally {
      _savingReview = false;
    }
  }

  void _refreshRating(String id) {
    final listing = _listings[id];
    if (listing == null) return;
    final summary = ReviewSummary(reviewsFor(id));
    _listings[id] = listing.withRating(summary.average, summary.total);
  }

  @override
  void dispose() {
    _disposed = true;
    bindUser(null);
    super.dispose();
  }

  List<Listing> get allProperties => List.unmodifiable(_listings.values);
  List<Listing> forOwner(String? ownerId) => List.unmodifiable(
    _listings.values.where(
      (listing) => ownerId != null && listing.ownerId == ownerId,
    ),
  );

  void updateOwnedListing(Listing draft, String ownerId) {
    final current = byId(draft.id);
    if (current == null || current.ownerId != ownerId) {
      throw StateError('This listing is no longer available to edit.');
    }
    // Preserve live reviews, views, ownership, and fields outside the edit form.
    upsert(
      current.copyWith(
        title: draft.title,
        address: draft.address,
        price: draft.price,
        availableRooms: draft.availableRooms,
        available: draft.available,
        photos: draft.photos,
        description: draft.description,
        contact: draft.contact,
      ),
    );
  }

  List<Listing> get favorites => List.unmodifiable(
    _listings.values.where((listing) => isFavorite(listing.id)),
  );
  Listing? byId(String? id) => _listings[id];
  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> saveOwnedListing(Listing draft, String ownerId) async {
    if (backend == null) {
      updateOwnedListing(draft, ownerId);
      return;
    }
    if (_user?.id != ownerId || draft.ownerId != ownerId) {
      throw StateError('Only the owner can edit this listing.');
    }
    if (!_pendingListings.add(draft.id)) {
      throw StateError('This listing is already being saved.');
    }
    try {
      final session = _session;
      final saved = await backend!.saveListing(draft, creating: false);
      if (session == _session && !_disposed) upsert(saved);
    } finally {
      _pendingListings.remove(draft.id);
    }
  }

  void toggleFavorite(String id) {
    if (!_listings.containsKey(id)) return;
    if (backend != null) {
      if (_user?.role != UserRole.boarder || !_pendingFavorites.add(id)) return;
      final session = _session;
      backend!
          .setFavorite(id, !isFavorite(id))
          .catchError((Object error) {
            if (session == _session && !_disposed) onError?.call(error);
          })
          .whenComplete(() {
            if (session == _session) _pendingFavorites.remove(id);
          });
      return;
    }
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
    if (_reviews.any((review) => review.listingId == listing.id)) {
      _refreshRating(listing.id);
    }
    notifyListeners();
  }

  void remove(String id) {
    _listings.remove(id);
    _favoriteIds.remove(id);
    notifyListeners();
  }
}
