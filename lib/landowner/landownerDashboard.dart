part of '../main.dart';

const _ownerInk = ink;
const _ownerMuted = muted;
const _ownerBlue = blue;

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({
    required this.store,
    required this.ownerId,
    required this.onListing,
    required this.onEdit,
    required this.onDelete,
    required this.onAddRoom,
    required this.onProfile,
    super.key,
  });

  final ListingStore store;
  final String? ownerId;
  final ValueChanged<Listing> onListing, onEdit, onDelete;
  final VoidCallback onAddRoom, onProfile;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: canvas,
    child: Column(
      children: [
        BrandHeader(onProfile: onProfile),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, child) {
              final listings = store.forOwner(ownerId);
              final active = listings.where((listing) => listing.available);
              final roomCount = active.fold<int>(
                0,
                (total, listing) => total + listing.availableRooms,
              );
              final views = listings.fold<int>(
                0,
                (total, listing) => total + listing.views,
              );
              return CustomScrollView(
                key: const PageStorageKey('landowner-dashboard-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Landowner Dashboard',
                            style: TextStyle(
                              fontSize: 23,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              color: _ownerInk,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Manage your property listings and track performance',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: _ownerMuted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.home_rounded,
                                  number: '${listings.length}',
                                  label: 'Total Listings',
                                  accent: _ownerBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.meeting_room,
                                  number: '$roomCount',
                                  label: 'Available Rooms',
                                  accent: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: StatCard(
                                  icon: Icons.visibility_outlined,
                                  number: '$views',
                                  label: 'Total Views',
                                  accent: _ownerBlue,
                                  iconColor: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  icon: Icons.check_circle_outline,
                                  number: '${active.length}',
                                  label: 'Active Listings',
                                  accent: _ownerBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Active Listings',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ownerInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (listings.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.home_work_outlined,
                        title: 'No listings yet',
                        text: 'Add a new room to publish your first listing.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          final listing = listings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ListingManagementCard(
                              key: ValueKey('owner-listing-${listing.id}'),
                              listing: listing,
                              onTap: () => onListing(listing),
                              onEdit: () => onEdit(listing),
                              onDelete: () => onDelete(listing),
                            ),
                          );
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: FilledButton.icon(
                        onPressed: onAddRoom,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 22),
                        label: const Text(
                          'Add New Room',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.accent,
    this.iconColor,
    super.key,
  });
  final IconData icon;
  final String number, label;
  final Color accent;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x030F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? accent, size: 22),
        const SizedBox(height: 2),
        Text(
          number,
          style: TextStyle(
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, height: 1.4, color: _ownerMuted),
        ),
      ],
    ),
  );
}

class ListingManagementCard extends StatelessWidget {
  const ListingManagementCard({
    required this.listing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final Listing listing;
  final VoidCallback onTap, onEdit, onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: line.withValues(alpha: .6)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: Photo(
              url: listing.photos.firstOrNull,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final name = Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ownerInk,
                      ),
                    );
                    final price = Text(
                      'PHP ${listing.formattedPrice}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ownerBlue,
                      ),
                    );
                    if (constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(16) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [name, const SizedBox(height: 6), price],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: price,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 9),
                ListingRating(
                  rating: listing.averageRating,
                  reviewCount: listing.reviewCount,
                ),
                const SizedBox(height: 12),
                ListingMeta(icon: Icons.location_on, text: listing.address),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    ListingMeta(
                      icon: Icons.visibility_outlined,
                      text: '${listing.views} views',
                      compact: true,
                    ),
                    ListingMeta(
                      icon: Icons.meeting_room,
                      text:
                          '${listing.available ? listing.availableRooms : 0}/${listing.totalRooms} available',
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListingMeta(
                  icon: Icons.phone,
                  text: listing.contact.isEmpty
                      ? 'No contact number'
                      : listing.contact,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEAF0F8)),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _status(),
                    _action(
                      'Edit',
                      Icons.edit,
                      _ownerBlue,
                      const Color(0xFFEFF6FF),
                      onEdit,
                    ),
                    _action(
                      'Delete',
                      Icons.delete_outline,
                      const Color(0xFFEF4444),
                      const Color(0xFFFFF1F2),
                      onDelete,
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

  Widget _status() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: listing.available
          ? const Color(0xFFF0FDF4)
          : const Color(0xFFFFF1F2),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: listing.available
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFE4E6),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 6,
          color: listing.available
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            listing.available ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 11,
              color: listing.available
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _action(
    String label,
    IconData icon,
    Color color,
    Color fill,
    VoidCallback onPressed,
  ) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: color,
      backgroundColor: fill,
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class ListingRating extends StatelessWidget {
  const ListingRating({
    required this.rating,
    required this.reviewCount,
    super.key,
  });
  final double rating;
  final int reviewCount;
  @override
  Widget build(BuildContext context) => reviewCount == 0
      ? const Text(
          'No ratings yet',
          style: TextStyle(fontSize: 11, color: _ownerMuted),
        )
      : Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF6A623)),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ownerInk,
              ),
            ),
            Text(
              '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
              style: const TextStyle(fontSize: 11, color: _ownerMuted),
            ),
          ],
        );
}

class ListingMeta extends StatelessWidget {
  const ListingMeta({
    required this.icon,
    required this.text,
    this.compact = false,
    super.key,
  });
  final IconData icon;
  final String text;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: const TextStyle(fontSize: 12, height: 1.5, color: _ownerMuted),
    );
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _ownerMuted),
        const SizedBox(width: 5),
        Flexible(child: label),
      ],
    );
  }
}
