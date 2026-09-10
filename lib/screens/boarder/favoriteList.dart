part of '../../main.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    required this.store,
    required this.onListing,
    required this.onHome,
    required this.onProfile,
    super.key,
  });

  final ListingStore store;
  final ValueChanged<Listing> onListing;
  final VoidCallback onHome, onProfile;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: line, width: .5)),
        ),
        child: const AppLogo(showRole: true, roleLabel: 'Boarder'),
      ),
      Expanded(
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, child) {
            final favoriteProperties = widget.store.favorites;
            final filteredFavorites = favoriteProperties
                .where(
                  (listing) =>
                      listing.matches(_searchController.text, const {}),
                )
                .toList();

            return CustomScrollView(
              key: const PageStorageKey('favorites-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'My Favorites',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save and manage your preferred boarding houses\nin one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: line.withValues(alpha: .6),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x030F172A),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saved Properties',
                                style: TextStyle(color: muted, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${favoriteProperties.length}',
                                key: const ValueKey('saved-properties-count'),
                                semanticsLabel:
                                    '${favoriteProperties.length} saved properties',
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 36,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          key: const ValueKey('favorites-search'),
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 14, color: ink),
                          decoration: InputDecoration(
                            hintText: 'Search favorites by name, location,\namenities..',
                            hintMaxLines: 2,
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: Color(0xFFA0AEC0),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 22,
                              color: Color(0xFF94A3B8),
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () =>
                                        setState(_searchController.clear),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: muted,
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: line.withValues(alpha: .6),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredFavorites.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: _FavoritesEmptyState(
                        hasFavorites: favoriteProperties.isNotEmpty,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList.builder(
                      itemCount: filteredFavorites.length,
                      itemBuilder: (context, index) {
                        final listing = filteredFavorites[index];
                        return Padding(
                          key: ValueKey(listing.id),
                          padding: EdgeInsets.only(
                            bottom: index == filteredFavorites.length - 1
                                ? 0
                                : 20,
                          ),
                          child: _FavoritePropertyCard(
                            listing: listing,
                            onRemove: () =>
                                widget.store.toggleFavorite(listing.id),
                            onTap: () => widget.onListing(listing),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      _FavoritesBottomNavigation(
        onHome: widget.onHome,
        onProfile: widget.onProfile,
      ),
    ],
  );
}

class _FavoritePropertyCard extends StatelessWidget {
  const _FavoritePropertyCard({
    required this.listing,
    required this.onRemove,
    required this.onTap,
  });

  final Listing listing;
  final VoidCallback onRemove, onTap;

  @override
  Widget build(BuildContext context) {
    final available = listing.available && listing.availableRooms > 0;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: line.withValues(alpha: .65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('property-${listing.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Photo(
                    url: listing.image,
                    height: constraints.maxWidth / 1.55,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: IconButton(
                    key: ValueKey('favorite-${listing.id}'),
                    tooltip: 'Remove from Favorites',
                    onPressed: onRemove,
                    isSelected: true,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      minimumSize: const Size(40, 40),
                    ),
                    icon: const Icon(Icons.favorite, size: 22),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: available ? const Color(0xFF34C99A) : muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${available ? listing.availableRooms : 0} Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: available
                                ? const Color(0xFFCCFBF1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            available ? 'AVAILABLE' : 'UNAVAILABLE',
                            key: ValueKey('favorite-status-${listing.id}'),
                            style: TextStyle(
                              color: available
                                  ? const Color(0xFF168D83)
                                  : muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BoarderListingRating(listing: listing),
                  const SizedBox(height: 14),
                  _FavoriteDetailLine(
                    icon: Icons.location_on_outlined,
                    text: listing.address.trim().isEmpty
                        ? 'Location not provided'
                        : listing.address,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    listing.description.trim().isEmpty
                        ? 'No description provided.'
                        : listing.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FavoriteDetailLine(
                    icon: Icons.phone_outlined,
                    text: listing.contact.trim().isEmpty
                        ? 'Contact number not provided'
                        : listing.contact,
                  ),
                  if (listing.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.amenities
                          .map(
                            (amenity) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: paleBlue,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: line.withValues(alpha: .5),
                                ),
                              ),
                              child: Text(
                                amenity,
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDetailLine extends StatelessWidget {
  const _FavoriteDetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, color: muted, size: 16),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: muted, fontSize: 14, height: 1.5),
        ),
      ),
    ],
  );
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState({required this.hasFavorites});
  final bool hasFavorites;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        hasFavorites ? Icons.search_off : Icons.favorite_border,
        color: muted,
        size: 36,
      ),
      const SizedBox(height: 12),
      Text(
        hasFavorites
            ? 'No matching favorites found'
            : 'No saved properties yet',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        hasFavorites
            ? 'Try another name, location, or amenity.'
            : 'Tap a property heart in Search to save it here.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
      ),
    ],
  );
}

class _FavoritesBottomNavigation extends StatelessWidget {
  const _FavoritesBottomNavigation({
    required this.onHome,
    required this.onProfile,
  });
  final VoidCallback onHome, onProfile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: line, width: .5)),
    ),
    child: Row(
      children: [
        _destination(
          context,
          icon: Icons.search,
          label: 'Search',
          onTap: onHome,
        ),
        _destination(
          context,
          icon: Icons.favorite_border,
          label: 'Favorites',
          onTap: () {},
          selected: true,
        ),
        _destination(
          context,
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: onProfile,
        ),
      ],
    ),
  );

  Widget _destination(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? blue : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: selected ? Colors.white : muted),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
