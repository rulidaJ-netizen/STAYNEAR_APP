part of '../../main.dart';

class BoarderHome extends StatefulWidget {
  const BoarderHome({
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onListing,
    required this.onFavorites,
    required this.onProfile,
    super.key,
  });
  final Listing listing;
  final bool favorite;
  final VoidCallback onFavorite, onListing, onFavorites, onProfile;
  @override
  State<BoarderHome> createState() => _BoarderHomeState();
}

class _BoarderHomeState extends State<BoarderHome> {
  String query = '';
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final listings =
        [
          widget.listing,
          Listing(
            title: 'ZaiLand BH',
            address: 'San Isidro, Cainta, Rizal',
            price: 1500,
            image: alternateRoomImage,
          ),
        ].where((item) {
          final text = '${item.title} ${item.address}'.toLowerCase();
          final matchesQuery =
              query.trim().isEmpty || text.contains(query.toLowerCase().trim());
          final matchesFilter = filter != 2 || item.price < 2000;
          return matchesQuery && matchesFilter;
        }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 9),
          child: Row(
            children: [
              const AppLogo(),
              const Spacer(),
              IconButton(
                onPressed: widget.onProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 21),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Perfect Boarding',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const Text(
                  'House',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: blue,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Discover comfortable and affordable places to stay.',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 17,
                        color: blue,
                      ),
                    ),
                    hintText: 'Search by location...',
                    hintStyle: const TextStyle(fontSize: 10),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: line),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterPill(
                      text: 'All',
                      selected: filter == 0,
                      onTap: () => setState(() => filter = 0),
                    ),
                    FilterPill(
                      text: 'Near me',
                      selected: filter == 1,
                      onTap: () => setState(() => filter = 1),
                    ),
                    FilterPill(
                      text: 'Under PHP 2,000',
                      selected: filter == 2,
                      onTap: () => setState(() => filter = 2),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                const Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (listings.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No listings found',
                    text: 'Try another location or filter.',
                  ),
                ...listings.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == listings.length - 1 ? 0 : 10,
                    ),
                    child: BoarderListingCard(
                      listing: entry.value,
                      favorite: entry.key == 0 && widget.favorite,
                      onFavorite: entry.key == 0 ? widget.onFavorite : () {},
                      onTap: entry.key == 0 ? widget.onListing : () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        BottomNav(
          index: 0,
          onHome: () {},
          onFavorites: widget.onFavorites,
          onProfile: widget.onProfile,
        ),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    required this.text,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? paleBlue : Colors.white,
        border: Border.all(color: selected ? blue : line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: selected ? blue : muted,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

class BoarderListingCard extends StatelessWidget {
  const BoarderListingCard({
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
    super.key,
  });
  final Listing listing;
  final bool favorite;
  final VoidCallback onFavorite, onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CardShell(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Photo(url: listing.image, height: 120),
                Positioned(
                  right: 9,
                  top: 9,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 17,
                        color: favorite ? const Color(0xFFF05461) : ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'PHP ${listing.price}/mo',
                        style: const TextStyle(
                          fontSize: 11,
                          color: blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: muted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        listing.address,
                        style: const TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SmallFeature(icon: Icons.bed_outlined, text: 'Furnished'),
                      SmallFeature(icon: Icons.wifi, text: 'Wi-Fi'),
                      SmallFeature(icon: Icons.ac_unit, text: 'Aircon'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallFeature extends StatelessWidget {
  const SmallFeature({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: Row(
      children: [
        Icon(icon, size: 12, color: muted),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 9, color: muted)),
      ],
    ),
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onListing,
    required this.onHome,
    required this.onProfile,
    super.key,
  });
  final Listing listing;
  final bool favorite;
  final VoidCallback onFavorite, onListing, onHome, onProfile;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TopBar(title: 'My Favorites', action: const SizedBox.shrink()),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
          child: favorite
              ? BoarderListingCard(
                  listing: listing,
                  favorite: true,
                  onFavorite: onFavorite,
                  onTap: onListing,
                )
              : EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No favorites yet',
                  text: 'Save boarding houses you like to see them here.',
                ),
        ),
      ),
      BottomNav(
        index: 1,
        onHome: onHome,
        onFavorites: () {},
        onProfile: onProfile,
      ),
    ],
  );
}

class ListingPage extends StatelessWidget {
  const ListingPage({
    required this.listing,
    required this.favorite,
    required this.onFavorite,
    required this.onBack,
    super.key,
  });
  final Listing listing;
  final bool favorite;
  final VoidCallback onFavorite, onBack;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TopBar(
        title: 'Property Details',
        onBack: onBack,
        action: IconButton(
          onPressed: onFavorite,
          icon: Icon(
            favorite ? Icons.favorite : Icons.favorite_border,
            color: favorite ? const Color(0xFFF05461) : ink,
            size: 20,
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardShell(
                padding: EdgeInsets.zero,
                child: Photo(url: listing.image, height: 190),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ),
                  Text(
                    'PHP ${listing.price}/mo',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    listing.address,
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'About This Property',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Comfortable boarding house with clean, well-maintained rooms '
                'in a convenient location. Perfect for students and working '
                'professionals.',
                style: TextStyle(fontSize: 10, color: muted, height: 1.5),
              ),
              const SizedBox(height: 15),
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: DetailFeature(
                      icon: Icons.ac_unit,
                      text: 'Air Conditioning',
                    ),
                  ),
                  Expanded(
                    child: DetailFeature(icon: Icons.wifi, text: 'Wi-Fi'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: DetailFeature(
                      icon: Icons.bed_outlined,
                      text: 'Furnished',
                    ),
                  ),
                  Expanded(
                    child: DetailFeature(
                      icon: Icons.local_laundry_service_outlined,
                      text: 'Laundry',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0E4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: line),
                ),
                child: const Center(
                  child: Icon(Icons.location_on, size: 35, color: blue),
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Contact Landowner'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class DetailFeature extends StatelessWidget {
  const DetailFeature({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: blue),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 10, color: ink)),
    ],
  );
}
