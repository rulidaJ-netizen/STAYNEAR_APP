part of '../../main.dart';

const _detailsBlue = Color(0xFF2864F5);
const _detailsInk = Color(0xFF202737);
const _detailsMuted = Color(0xFF667085);
const _detailsLine = Color(0xFFE6E8ED);
const _detailsGold = Color(0xFFFFBD19);

/// Shared listing data with feedback actions determined by the signed-in role.
class ListingPage extends StatefulWidget {
  const ListingPage({
    required this.listing,
    required this.store,
    required this.favorite,
    required this.onFavorite,
    required this.onBack,
    this.user,
    this.locationService,
    this.additionalInformation = const {},
    this.onEdit,
    super.key,
  });
  final Listing listing;
  final ListingStore store;
  final UserProfile? user;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback? onFavorite, onEdit;
  final PropertyLocationService? locationService;
  final Map<String, String> additionalInformation;

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  final _comment = TextEditingController();
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _reviewsKey = GlobalKey();
  late final PropertyLocationService _location;
  int _photo = 0, _rating = 0;
  bool _loadingMap = false, _loadingReviews = true, _submitting = false;
  bool _locating = false;
  String? _reviewError, _formError;
  PropertyLocationException? _locationError;
  LatLng? _point, _origin;

  Listing get _listing =>
      widget.store.byId(widget.listing.id) ?? widget.listing;
  bool get _isLandowner => widget.user?.role == UserRole.landlord;

  @override
  void initState() {
    super.initState();
    _location = widget.locationService ?? PropertyLocationService();
    _resolveLocation();
    _loadReviews();
  }

  @override
  void didUpdateWidget(covariant ListingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.address != widget.listing.address ||
        oldWidget.listing.latitude != widget.listing.latitude ||
        oldWidget.listing.longitude != widget.listing.longitude) {
      _resolveLocation();
    }
    if (oldWidget.listing.photos.join('\n') !=
        widget.listing.photos.join('\n')) {
      _photo = 0;
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    _name.dispose();
    super.dispose();
  }

  void _resolveLocation() {
    final listing = _listing;
    setState(() {
      _point = PropertyLocationService.coordinates(
        listing.latitude,
        listing.longitude,
      );
      _loadingMap = false;
    });
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
      _reviewError = null;
    });
    try {
      await widget.store.loadReviews();
    } catch (_) {
      if (mounted) {
        setState(
          () => _reviewError = 'Could not load saved reviews. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await _location.open(uri)) {
        _message('Could not open Maps. Please try again.');
      }
    } catch (_) {
      _message('Could not open Maps. Please try again.');
    }
  }

  Future<void> _directions() async {
    if (_locating) return;
    final point = PropertyLocationService.coordinates(
      _listing.latitude,
      _listing.longitude,
    );
    if (point == null) {
      _message(
        'The exact location for this boardinghouse is not available yet.',
      );
      return;
    }
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      await _open(PropertyLocationService.directionsUri(point));
    } catch (_) {
      _message('Could not open Maps. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_isLandowner) return;
    final valid = _form.currentState!.validate();
    setState(
      () => _formError = _rating == 0 ? 'Please select a star rating.' : null,
    );
    if (!valid || _rating == 0) return;
    final user = widget.user;
    if (user == null || user.role != UserRole.boarder) {
      setState(() => _formError = 'Sign in as a boarder to leave a review.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.store.submitReview(
        listingId: _listing.id,
        user: user,
        rating: _rating,
        comment: _comment.text,
        displayName: _name.text,
      );
      if (!mounted || _isLandowner) return;
      _comment.clear();
      _name.clear();
      _form.currentState!.reset();
      setState(() {
        _rating = 0;
        _formError = null;
      });
      FocusManager.instance.primaryFocus?.unfocus();
      _message('Review submitted successfully.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _formError =
              'Could not save your review. Your text is kept; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) widget.onBack();
    },
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: _detailsInk, displayColor: _detailsInk),
        colorScheme: ColorScheme.fromSeed(seedColor: _detailsBlue),
      ),
      child: Material(
        color: Colors.white,
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, child) {
            final listing = _listing;
            final reviews = widget.store.reviewsFor(listing.id);
            final summary = ReviewSummary(reviews);
            final visibleInformation = {
              ...listing.houseInformation,
              ...widget.additionalInformation,
            }..remove('Reference Map');
            final landownerName = visibleInformation
                .remove('Landowner')
                ?.trim();
            final distance = visibleInformation
                .remove('Distance from University')
                ?.trim();
            return SingleChildScrollView(
              key: ValueKey('full-details-${listing.id}'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLandowner)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back, size: 22),
                          ),
                          const Expanded(
                            child: Text(
                              'Boarding House Details',
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back, size: 22),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: widget.onFavorite,
                            tooltip: widget.favorite
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            icon: Icon(
                              widget.favorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.favorite ? Colors.red : _detailsInk,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _hero(listing),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _isLandowner
                                    ? 'Landowner Dashboard > '
                                    : 'Home > Search Results > ',
                                style: const TextStyle(color: _detailsMuted),
                              ),
                              TextSpan(
                                text: listing.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        _heading(listing, summary),
                        if (_isLandowner &&
                            listing.ownerId == widget.user?.id &&
                            widget.onEdit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: OutlinedButton.icon(
                              key: const ValueKey('edit-listing-details'),
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Listing'),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(height: 1, color: _detailsLine),
                        ),
                        const _DetailsTitle('About This Property'),
                        const SizedBox(height: 10),
                        Text(
                          listing.description.trim().isEmpty
                              ? 'No description provided.'
                              : listing.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: _detailsMuted,
                          ),
                        ),
                        if (listing.totalRooms > 0 ||
                            listing.availableRooms > 0 ||
                            listing.contact.trim().isNotEmpty ||
                            (landownerName?.isNotEmpty ?? false) ||
                            (distance?.isNotEmpty ?? false) ||
                            visibleInformation.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (listing.totalRooms > 0 ||
                                    listing.availableRooms > 0)
                                  _information(
                                    'Rooms',
                                    '${listing.available ? listing.availableRooms : 0} available${listing.totalRooms > 0 ? ' / ${listing.totalRooms} total' : ''}',
                                  ),
                                if (landownerName?.isNotEmpty ?? false)
                                  _information('Landowner', landownerName!),
                                if (distance?.isNotEmpty ?? false)
                                  _information(
                                    'Distance from University',
                                    distance!,
                                  ),
                                for (final item in visibleInformation.entries)
                                  _information(item.key, item.value),
                                if (listing.contact.trim().isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 18,
                                        color: _detailsBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectableText(
                                          listing.contact,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _detailsMuted,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Copy contact number',
                                        icon: const Icon(
                                          Icons.copy_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: listing.contact,
                                            ),
                                          );
                                          _message('Contact number copied');
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        _features(listing),
                        const SizedBox(height: 28),
                        const _DetailsTitle('Location'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: _detailsBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: SelectableText(
                                listing.address.trim().isEmpty
                                    ? 'No address provided.'
                                    : listing.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _detailsMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (PropertyLocationService.savedMapUri(
                                  listing.houseInformation['Reference Map'],
                                ) !=
                                null ||
                            _point != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: _detailsBlue,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => _open(
                                _point != null
                                    ? PropertyLocationService.mapUri(
                                        _point,
                                        listing.address,
                                      )
                                    : PropertyLocationService.savedMapUri(
                                        listing
                                            .houseInformation['Reference Map'],
                                      )!,
                              ),
                              child: const Text(
                                'View on Google Maps',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        _map(listing),
                        const SizedBox(height: 16),
                        _directionsCard(listing),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Divider(height: 1, color: _detailsLine),
                        ),
                        _reviewHeading(summary),
                        const SizedBox(height: 16),
                        if (_loadingReviews)
                          const LinearProgressIndicator()
                        else if (_reviewError != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _reviewError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: _loadReviews,
                                child: const Text('Retry reviews'),
                              ),
                            ],
                          )
                        else
                          _ratingSummary(summary),
                        if (!_isLandowner) ...[
                          const SizedBox(height: 16),
                          _reviewForm(),
                        ],
                        const SizedBox(height: 24),
                        if (!_loadingReviews &&
                            _reviewError == null &&
                            reviews.isEmpty)
                          _DetailsCard(
                            child: Text(
                              _isLandowner ? 'No reviews yet.' : 'No reviews yet. Be the first to share your experience.',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: _detailsMuted,
                              ),
                            ),
                          ),
                        for (final review in reviews)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _DetailsReviewCard(review: review),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _hero(Listing listing) => AspectRatio(
    aspectRatio: 4 / 3,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          if (listing.photos.isEmpty)
            Photo(
              url: null,
              height: constraints.maxHeight,
              borderRadius: BorderRadius.zero,
            )
          else
            PageView.builder(
              key: ValueKey('${listing.id}-${listing.photos.join('|')}'),
              itemCount: listing.photos.length,
              onPageChanged: (index) => setState(() => _photo = index),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _gallery(listing, index),
                child: Photo(
                  url: listing.photos[index],
                  height: constraints.maxHeight,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _photoPill(
                  color: listing.available
                      ? const Color(0xFF00A775)
                      : const Color(0xFF667085),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 7),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          listing.available ? 'Available Now' : 'Unavailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: listing.photos.isNotEmpty,
                  label: 'View property photos',
                  child: GestureDetector(
                    onTap: listing.photos.isEmpty
                        ? null
                        : () => _gallery(listing, _photo),
                    child: _photoPill(
                      color: const Color(0xAA202737),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            listing.photos.isEmpty
                                ? '0 Photos'
                                : '${_photo + 1}/${listing.photos.length} Photos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _photoPill({required Color color, required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );

  Future<void> _gallery(Listing listing, int initial) async {
    final controller = PageController(initialPage: initial);
    var current = initial;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Close photos',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        '${current + 1}/${listing.photos.length} Photos',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous photo',
                      onPressed: current == 0
                          ? null
                          : () => controller.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Next photo',
                      onPressed: current == listing.photos.length - 1
                          ? null
                          : () => controller.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: listing.photos.length,
                    onPageChanged: (value) => update(() => current = value),
                    itemBuilder: (context, index) => Center(
                      child: InteractiveViewer(
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: LayoutBuilder(
                            builder: (context, size) => Photo(
                              url: listing.photos[index],
                              height: size.maxHeight,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Dialog route transitions finish after the returned future completes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  Widget _heading(Listing listing, ReviewSummary summary) => LayoutBuilder(
    builder: (context, size) {
      final price = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'PHP ${listing.formattedPrice}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '/mo', style: TextStyle(fontSize: 11)),
              ],
            ),
            style: const TextStyle(color: _detailsBlue),
          ),
          if (listing.billingInfo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                listing.billingInfo,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3)),
              ),
            ),
        ],
      );
      final name = Text(
        listing.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (size.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 18)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, const SizedBox(height: 8), price],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: name),
                const SizedBox(width: 12),
                Expanded(child: price),
              ],
            ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 17, color: Color(0xFFFF9800)),
                  const SizedBox(width: 3),
                  Text(
                    summary.total == 0
                        ? (_isLandowner ? 'No ratings yet' : 'New')
                        : summary.average.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Text('•', style: TextStyle(color: Color(0xFFD0D5DD))),
              InkWell(
                onTap: () {
                  final target = _reviewsKey.currentContext;
                  if (target != null) {
                    Scrollable.ensureVisible(
                      target,
                      duration: const Duration(milliseconds: 350),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${summary.total} ${summary.total == 1 ? 'Review' : 'Reviews'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _detailsBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _information(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(fontSize: 13, color: _detailsMuted, height: 1.5),
    ),
  );

  Widget _features(Listing listing) => _DetailsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailsTitle('Features', size: 16),
        const SizedBox(height: 20),
        if (listing.amenities.isEmpty)
          const Text(
            'No amenities listed.',
            style: TextStyle(color: _detailsMuted, fontSize: 13),
          )
        else
          LayoutBuilder(
            builder: (context, size) {
              final columns =
                  size.maxWidth < 240 ||
                      MediaQuery.textScalerOf(context).scale(12) > 18
                  ? 1
                  : 2;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: listing.amenities
                    .map(
                      (amenity) => SizedBox(
                        width: (size.maxWidth - (columns - 1) * 12) / columns,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEFF5FF),
                              ),
                              child: Icon(
                                _amenityIcon(amenity),
                                size: 20,
                                color: _detailsBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                amenity,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    ),
  );

  IconData _amenityIcon(String name) => switch (normalizeListingText(name)) {
    'air conditioning' => Icons.ac_unit,
    'refrigerator' => Icons.kitchen,
    'private bathroom' => Icons.bathtub,
    'cctv' => Icons.videocam,
    'parking' => Icons.directions_car,
    'laundry area' => Icons.local_laundry_service,
    'study table' || 'study desk' => Icons.menu_book,
    'wifi' => Icons.wifi,
    'shared kitchen' => Icons.countertops,
    'balcony' => Icons.balcony,
    'furnished' => Icons.chair,
    _ => Icons.check_circle_outline,
  };

  Widget _map(Listing listing) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD0D5DD)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF2F4F7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            'Property Details - ${listing.title}',
            style: const TextStyle(fontSize: 11, color: _detailsMuted),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 210),
          height: _loadingMap || _point != null ? 210 : null,
          child: _loadingMap
              ? const Center(child: CircularProgressIndicator())
              : _point == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: _detailsBlue,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Map preview unavailable. Use the Google Maps link to find this address.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: _detailsMuted,
                            height: 1.5,
                          ),
                        ),
                        TextButton(
                          onPressed: _resolveLocation,
                          child: const Text('Retry map'),
                        ),
                      ],
                    ),
                  ),
                )
              : _PropertyMap(
                  key: ValueKey('${_point!.latitude},${_point!.longitude}'),
                  point: _point!,
                  origin: _origin,
                  title: listing.title,
                  onAttribution: () => _open(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
        ),
      ],
    ),
  );

  Widget _directionsCard(Listing listing) => _DetailsCard(
    color: const Color(0xFFF8FBFF),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailsTitle('From Your Location', size: 15),
        const SizedBox(height: 6),
        Text(
          !_isLandowner &&
                  _origin != null &&
                  PropertyLocationService.coordinates(
                        listing.latitude,
                        listing.longitude,
                      ) !=
                      null
              ? '${PropertyLocationService.formatDistance(PropertyLocationService.distanceBetween(_origin!, LatLng(listing.latitude!, listing.longitude!)))} away (straight-line distance)'
              : 'Find your route to this boarding house.',
          style: const TextStyle(fontSize: 12, color: _detailsMuted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _locating ? null : _directions,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.directions, size: 18),
            label: Text(_locating ? 'Opening Google Maps…' : 'Get Directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _detailsBlue,
              side: const BorderSide(color: Color(0xFFD9E6FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Text(
            _locationError!.message,
            style: const TextStyle(
              fontSize: 12,
              color: _detailsMuted,
              height: 1.5,
            ),
          ),
          if (_locationError!.problem == LocationProblem.disabled ||
              _locationError!.problem == LocationProblem.deniedForever)
            TextButton(
              onPressed: () async {
                try {
                  if (!await _location.openSettings(_locationError!.problem)) {
                    _message(
                      'Please open your device settings to enable location.',
                    );
                  }
                } catch (_) {
                  _message(
                    'Please open your device settings to enable location.',
                  );
                }
              },
              child: const Text('Open settings'),
            ),
        ],
      ],
    ),
  );

  Widget _reviewHeading(ReviewSummary summary) => Column(
    key: _reviewsKey,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            const _DetailsTitle('Ratings & Reviews', size: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${summary.total} ${summary.total == 1 ? 'Review' : 'Reviews'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _detailsBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Reviews from boarders.',
        style: TextStyle(fontSize: 12, color: _detailsMuted),
      ),
    ],
  );

  Widget _ratingSummary(ReviewSummary summary) => _DetailsCard(
    color: const Color(0xFFFFFEFA),
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, size) {
        final score = Column(
          children: [
            Text(
              summary.average.toStringAsFixed(1),
              key: const ValueKey('average-rating'),
              style: const TextStyle(
                fontSize: 36,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            _DetailsStars(rating: summary.average, size: 15),
            const SizedBox(height: 5),
            const Text(
              'out of 5.0',
              style: TextStyle(fontSize: 11, color: _detailsMuted),
            ),
          ],
        );
        final bars = Column(
          children: [
            for (var star = 5; star >= 1; star--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      child: Text(
                        '$star',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _detailsMuted,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 12, color: _detailsGold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: summary.total == 0
                            ? 0
                            : summary.counts[star]! / summary.total,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: _detailsGold,
                        backgroundColor: const Color(0xFFE4E6EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${summary.counts[star]}',
                        textAlign: TextAlign.end,
                        key: ValueKey('rating-count-$star'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _detailsMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        if (size.maxWidth < 250 ||
            MediaQuery.textScalerOf(context).scale(12) > 18) {
          return Column(children: [score, const SizedBox(height: 16), bars]);
        }
        return Row(
          children: [
            SizedBox(width: 88, child: score),
            const SizedBox(width: 16),
            Expanded(child: bars),
          ],
        );
      },
    ),
  );

  Widget _reviewForm() => _DetailsCard(
    color: const Color(0xFFFAFCFF),
    borderColor: const Color(0xFFD9E6FF),
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, size: 18, color: _detailsBlue),
              SizedBox(width: 8),
              Expanded(
                child: _DetailsTitle('Leave a Review or Rating', size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate this room:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _detailsMuted,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var star = 1; star <= 5; star++)
                    Semantics(
                      selected: star == _rating,
                      child: IconButton(
                        key: ValueKey('review-star-$star'),
                        tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _rating = star;
                                _formError = null;
                              }),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 44,
                        ),
                        icon: Icon(
                          Icons.star,
                          size: 28,
                          color: star <= _rating
                              ? _detailsGold
                              : const Color(0xFFD0D5DD),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                _rating == 0
                    ? 'Select a rating'
                    : '$_rating.0 (${const ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating - 1]})',
                style: const TextStyle(
                  fontSize: 12,
                  color: _detailsMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.user?.fullName.trim().isNotEmpty ?? false) ...[
            Text(
              'Reviewing as ${widget.user!.fullName}',
              style: const TextStyle(fontSize: 12, color: _detailsMuted),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'Your Name',
              style: TextStyle(fontSize: 12, color: _detailsMuted),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _name,
              enabled: !_submitting,
              style: const TextStyle(fontSize: 12),
              decoration: _input('Enter your name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter your name.'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            'Your Review / Comments',
            style: TextStyle(fontSize: 12, color: _detailsMuted),
          ),
          const SizedBox(height: 5),
          TextFormField(
            key: const ValueKey('review-comment'),
            controller: _comment,
            enabled: !_submitting,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 12, height: 1.5),
            decoration: _input(
              'Write your comments regarding the room, Wi-Fi signal, cleanliness, water, or neighborhood...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please write your review.'
                : null,
          ),
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _formError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('submit-review'),
              onPressed: _submitting || _loadingReviews || _reviewError != null
                  ? null
                  : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 15),
              label: Text(
                _submitting ? 'Saving…' : 'Submit Review',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _detailsBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(
      fontSize: 12,
      height: 1.5,
      color: Color(0xFF7A8498),
    ),
    contentPadding: const EdgeInsets.all(12),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _detailsLine),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _detailsLine),
    ),
  );
}

class _DetailsTitle extends StatelessWidget {
  const _DetailsTitle(this.text, {this.size = 18});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: _detailsInk,
      height: 1.3,
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.child,
    this.color = Colors.white,
    this.borderColor = _detailsLine,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color color, borderColor;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: child,
  );
}

class _DetailsStars extends StatelessWidget {
  const _DetailsStars({required this.rating, this.size = 13});
  final double rating, size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${rating.toStringAsFixed(1)} out of 5 stars',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          rating >= index + 1
              ? Icons.star
              : rating > index
              ? Icons.star_half
              : Icons.star_border,
          size: size,
          color: _detailsGold,
        ),
      ),
    ),
  );
}

class _DetailsReviewCard extends StatelessWidget {
  const _DetailsReviewCard({required this.review});
  final PropertyReview review;
  @override
  Widget build(BuildContext context) {
    final parts = review.boarderName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : '${parts.first.characters.first}${parts.length > 1 ? parts.last.characters.first : ''}'
              .toUpperCase();
    final age = DateTime.now().difference(review.createdAt);
    final date = age.inMinutes < 1
        ? 'Just now'
        : age.inHours < 1
        ? '${age.inMinutes}m ago'
        : age.inDays < 1
        ? '${age.inHours}h ago'
        : age.inDays < 7
        ? '${age.inDays}d ago'
        : '${review.createdAt.toLocal().month}/${review.createdAt.toLocal().day}/${review.createdAt.toLocal().year}';
    return _DetailsCard(
      color: const Color(0xFFFAFBFC),
      borderColor: const Color(0xFFF0F1F3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFD8F9EB),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF008B65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            review.boarderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _DetailsStars(rating: review.rating.toDouble()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Boarder · $date',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _detailsMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 12,
              color: _detailsMuted,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyMap extends StatefulWidget {
  const _PropertyMap({
    required this.point,
    required this.origin,
    required this.title,
    required this.onAttribution,
    super.key,
  });
  final LatLng point;
  final LatLng? origin;
  final String title;
  final VoidCallback onAttribution;
  @override
  State<_PropertyMap> createState() => _PropertyMapState();
}

class _PropertyMapState extends State<_PropertyMap> {
  final _controller = MapController();
  bool _tileError = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: widget.point,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.stay_near',
            errorTileCallback: (tile, error, stack) {
              if (_tileError || !mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _tileError = true);
              });
            },
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.point,
                width: 170,
                height: 65,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 38,
                      color: Color(0xFFE53935),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.title,
                        // Map labels follow map geometry; surrounding UI still scales.
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.origin != null)
                Marker(
                  point: widget.origin!,
                  width: 24,
                  height: 24,
                  child: const Tooltip(
                    message: 'Your current location',
                    child: Icon(
                      Icons.my_location,
                      color: _detailsBlue,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: widget.onAttribution,
              ),
            ],
          ),
        ],
      ),
      Positioned(
        right: 8,
        top: 8,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              IconButton(
                tooltip: 'Zoom in',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _controller.move(
                  _controller.camera.center,
                  (_controller.camera.zoom + 1).clamp(2, 19),
                ),
              ),
              IconButton(
                tooltip: 'Zoom out',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () => _controller.move(
                  _controller.camera.center,
                  (_controller.camera.zoom - 1).clamp(2, 19),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_tileError)
        const Positioned(
          left: 8,
          right: 60,
          top: 8,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Map tiles unavailable. Check your connection.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
    ],
  );
}
