part of '../../main.dart';

/// Listing summary card; favorite state belongs to ListingStore.
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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: line.withValues(alpha: .6)),
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
                  height: constraints.maxWidth / 1.8,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: IconButton(
                  key: ValueKey('favorite-${listing.id}'),
                  onPressed: onFavorite,
                  tooltip: favorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  isSelected: favorite,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: favorite ? const Color(0xFFEF4444) : muted,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    size: 23,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: listing.available && listing.availableRooms > 0
                        ? const Color(0xFF22A866)
                        : muted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${listing.available ? listing.availableRooms : 0} Available',
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final title = Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    );
                    final price = Text.rich(
                      TextSpan(
                        text: 'PHP ${listing.formattedPrice}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: blue,
                        ),
                        children: const [
                          TextSpan(
                            text: ' /mo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    );
                    if (constraints.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(16) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 6), price],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 12),
                        Flexible(child: price),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 9),
                BoarderListingRating(listing: listing),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        listing.address,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ),
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

class BoarderListingRating extends StatelessWidget {
  const BoarderListingRating({required this.listing, super.key});
  final Listing listing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF6A623)),
      Text(
        listing.averageRating.toStringAsFixed(1),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      Text(
        '(${listing.reviewCount} ${listing.reviewCount == 1 ? 'review' : 'reviews'})',
        style: const TextStyle(fontSize: 11, color: muted),
      ),
    ],
  );
}
