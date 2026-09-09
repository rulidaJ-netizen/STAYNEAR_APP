part of '../../main.dart';

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
    required this.onAddRoom,
    required this.onProfile,
    super.key,
  });
  final Listing? listing;
  final VoidCallback onEdit, onDelete, onAddRoom, onProfile;
  @override
  Widget build(BuildContext context) {
    final availableRooms = listing?.availableRooms ?? 0;
    final activeListings = listing?.available == true ? 1 : 0;
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: line)),
          ),
          child: BrandHeader(onProfile: onProfile),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Landowner Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const Text(
                'Manage your property listings and track performance',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.home_outlined,
                      number: listing == null ? '0' : '1',
                      label: 'Total Listings',
                      accent: blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      icon: Icons.business_outlined,
                      number: '$availableRooms',
                      label: 'Available Rooms',
                      accent: const Color(0xFF1BAA70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.visibility_outlined,
                      number: '${listing?.views ?? 0}',
                      label: 'Total Views',
                      accent: blue,
                      iconColor: muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      icon: Icons.add_circle_outline,
                      number: '$activeListings',
                      label: 'Active Listings',
                      accent: blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Listings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 14),
                    children: [
                      if (listing == null)
                        const EmptyState(
                          icon: Icons.home_work_outlined,
                          title: 'No listings yet',
                          text: 'Add a new room to publish your first listing.',
                        )
                      else
                        ListingManagementCard(
                          listing: listing!,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 40,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddRoom,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Add New Room',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
  final String number;
  final String label;
  final Color accent;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? accent, size: 16),
        const SizedBox(height: 1),
        Text(
          number,
          style: TextStyle(
            fontSize: 16,
            height: 1,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
        const Spacer(),
        Text(label, style: const TextStyle(fontSize: 9, color: muted)),
      ],
    ),
  );
}

class ListingManagementCard extends StatelessWidget {
  const ListingManagementCard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final Listing listing;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 7, offset: Offset(0, 2)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(url: listing.image, height: 104),
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
                    'PHP ${listing.price}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ListingRating(
                rating: listing.averageRating,
                reviewCount: listing.reviewCount,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: muted,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      listing.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ListingMeta(
                    icon: Icons.visibility_outlined,
                    text: '${listing.views} views',
                  ),
                  ListingMeta(
                    icon: Icons.meeting_room_outlined,
                    text:
                        '${listing.availableRooms}/${listing.totalRooms == 0 ? listing.availableRooms : listing.totalRooms} available',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: listing.available
                          ? const Color(0xFFE9FBF4)
                          : const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 5,
                          color: listing.available
                              ? const Color(0xFF1BAA70)
                              : const Color(0xFFD04C4C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.available ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 9,
                            color: listing.available
                                ? const Color(0xFF1BAA70)
                                : const Color(0xFFD04C4C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 11),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 9),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      backgroundColor: paleBlue,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 11),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 9),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE75252),
                      backgroundColor: const Color(0xFFFFF0F0),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

class ListingRating extends StatelessWidget {
  const ListingRating({required this.rating, required this.reviewCount, super.key});
  final double rating;
  final int reviewCount;
  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return const Text(
        'No ratings yet',
        style: TextStyle(fontSize: 9, color: muted),
      );
    }
    return Row(
      children: [
        ...List.generate(
          5,
          (index) => Icon(
            index < rating.round() ? Icons.star : Icons.star_border,
            size: 12,
            color: const Color(0xFFFFB400),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount reviews)',
          style: const TextStyle(fontSize: 9, color: muted),
        ),
      ],
    );
  }
}

class ListingMeta extends StatelessWidget {
  const ListingMeta({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: Row(
      children: [
        Icon(icon, size: 11, color: muted),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 9, color: muted)),
      ],
    ),
  );
}

class EditListingPage extends StatefulWidget {
  const EditListingPage({
    required this.listing,
    required this.onBack,
    required this.onSave,
    super.key,
  });
  final Listing listing;
  final VoidCallback onBack;
  final ValueChanged<Listing> onSave;
  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late final TextEditingController name = TextEditingController(
    text: widget.listing.title,
  );
  late final TextEditingController price = TextEditingController(
    text: 'PHP ${widget.listing.price}',
  );
  late final TextEditingController address = TextEditingController(
    text: widget.listing.address,
  );
  late final TextEditingController image = TextEditingController(
    text: widget.listing.image ?? '',
  );
  late final TextEditingController availableRooms = TextEditingController(
    text: '${widget.listing.availableRooms}',
  );
  late final TextEditingController description = TextEditingController(
    text: 'Comfortable boarding house located in a quiet neighborhood.',
  );
  late bool available = widget.listing.available;

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    address.dispose();
    image.dispose();
    availableRooms.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      BrandHeader(onProfile: widget.onBack),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Listing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const Text(
                'Update property details and availability.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              const SizedBox(height: 12),
              CardShell(
                padding: EdgeInsets.zero,
                child: Photo(url: image.text, height: 190),
              ),
              const SizedBox(height: 12),
              CardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Listing Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    RadioGroup<bool>(
                      groupValue: available,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => available = v);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: true,
                            title: const Text(
                              'Available',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          RadioListTile<bool>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: false,
                            title: const Text(
                              'Unavailable',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Property Name'),
                    TextFieldBox(controller: name),
                    const FieldLabel('Monthly Price'),
                    TextFieldBox(controller: price),
                    const FieldLabel('Available Rooms'),
                    TextFieldBox(controller: availableRooms),
                    const FieldLabel('Location'),
                    TextFieldBox(controller: address),
                    const FieldLabel('Listing Photo URL'),
                    TextFieldBox(
                      controller: image,
                      hint: 'https://...',
                    ),
                    const FieldLabel('Contact Number'),
                    const TextFieldBox(hint: '0912 345 6789'),
                    const FieldLabel('Description'),
                    TextFieldBox(controller: description, maxLines: 4),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final parsed =
                            int.tryParse(
                              price.text.replaceAll(RegExp(r'[^0-9]'), ''),
                            ) ??
                            widget.listing.price;
                        widget.onSave(
                          Listing(
                            title: name.text.trim().isEmpty
                                ? widget.listing.title
                                : name.text.trim(),
                            address: address.text.trim().isEmpty
                                ? widget.listing.address
                                : address.text.trim(),
                            price: parsed,
                            image: image.text.trim().isEmpty
                                ? null
                                : image.text.trim(),
                            availableRooms:
                                int.tryParse(availableRooms.text.trim()) ??
                                widget.listing.availableRooms,
                            totalRooms: widget.listing.totalRooms,
                            views: widget.listing.views,
                            averageRating: widget.listing.averageRating,
                            reviewCount: widget.listing.reviewCount,
                            available: available,
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
