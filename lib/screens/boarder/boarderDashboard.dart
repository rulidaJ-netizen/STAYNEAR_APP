part of '../../main.dart';

class BoarderDashboard extends StatefulWidget {
  const BoarderDashboard({
    required this.store,
    required this.onListing,
    required this.onFavorites,
    required this.onProfile,
    super.key,
  });
  final ListingStore store;
  final ValueChanged<Listing> onListing;
  final VoidCallback onFavorites, onProfile;

  @override
  State<BoarderDashboard> createState() => _BoarderDashboardState();
}

class _BoarderDashboardState extends State<BoarderDashboard> {
  final _searchController = TextEditingController();
  final Set<String> _selectedAmenities = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedAmenities.clear();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, child) {
      final allProperties = widget.store.allProperties;
      final filteredProperties = allProperties
          .where(
            (listing) =>
                listing.matches(_searchController.text, _selectedAmenities),
          )
          .toList();
      final amenityLabels = <String, String>{};
      for (final label in [
        'WiFi',
        'Air Conditioning',
        'Study Desk',
        'Shared Kitchen',
        'Private Bathroom',
        'Parking',
        'Laundry Area',
        'Water Included',
        'Electricity Included',
        ...allProperties.expand((listing) => listing.amenities),
      ]) {
        if (label.trim().isNotEmpty) {
          amenityLabels.putIfAbsent(
            normalizeListingText(label),
            () => label.trim(),
          );
        }
      }
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: line, width: .5)),
            ),
            child: const AppLogo(showRole: true, roleLabel: 'Boarder'),
          ),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('boarder-search-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Find Your Perfect Boarding\nHouse',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Search from hundreds of verified properties near\nyour university',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          key: const ValueKey('boarder-search'),
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: const TextStyle(fontSize: 12, color: ink),
                          decoration: InputDecoration(
                            hintText: 'Search by location or property name...',
                            hintStyle: const TextStyle(
                              fontSize: 11,
                              color: muted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 22,
                              color: muted,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(color: line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(color: blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: line.withValues(alpha: .6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 19,
                                    color: ink,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Filter by Amenities',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                key: const ValueKey('amenity-scroll'),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: amenityLabels.entries
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: FilterChip(
                                            key: ValueKey(
                                              'amenity-${entry.key}',
                                            ),
                                            label: Text(entry.value),
                                            selected: _selectedAmenities
                                                .contains(entry.key),
                                            onSelected: (selected) =>
                                                setState(() {
                                                  if (selected) {
                                                    _selectedAmenities.add(
                                                      entry.key,
                                                    );
                                                  } else {
                                                    _selectedAmenities.remove(
                                                      entry.key,
                                                    );
                                                  }
                                                }),
                                            showCheckmark: false,
                                            backgroundColor: paleBlue,
                                            selectedColor: blue,
                                            side: BorderSide.none,
                                            shape: const StadiumBorder(),
                                            labelStyle: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  _selectedAmenities.contains(
                                                    entry.key,
                                                  )
                                                  ? Colors.white
                                                  : blue,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            Text(
                              '${filteredProperties.length} ${filteredProperties.length == 1 ? 'property' : 'properties'} found',
                              key: const ValueKey('property-count'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            TextButton(
                              onPressed: _clearFilters,
                              style: TextButton.styleFrom(
                                foregroundColor: blue,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Clear all filters'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (filteredProperties.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'No properties found',
                        text: 'Try changing your search or filters.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filteredProperties.length,
                      itemBuilder: (context, index) {
                        final listing = filteredProperties[index];
                        return Padding(
                          key: ValueKey(listing.id),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BoarderListingCard(
                            listing: listing,
                            favorite: widget.store.isFavorite(listing.id),
                            onFavorite: () =>
                                widget.store.toggleFavorite(listing.id),
                            onTap: () => widget.onListing(listing),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          BottomNav(
            index: 0,
            onHome: () => FocusScope.of(context).unfocus(),
            onFavorites: widget.onFavorites,
            onProfile: widget.onProfile,
          ),
        ],
      );
    },
  );
}
