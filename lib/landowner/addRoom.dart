part of '../main.dart';

class RoomWizard extends StatefulWidget {
  const RoomWizard({
    required this.step,
    required this.onBack,
    required this.onProfile,
    required this.onNext,
    required this.onPrevious,
    required this.onPublish,
    this.onPublished,
    this.photoPicker,
    super.key,
  });
  final int step;
  final VoidCallback onBack, onProfile, onNext, onPrevious;
  final FutureOr<void> Function(Listing) onPublish;
  final VoidCallback? onPublished;
  final ProfilePhotoPicker? photoPicker;
  @override
  State<RoomWizard> createState() => _RoomWizardState();
}

class _RoomWizardState extends State<RoomWizard> {
  final name = TextEditingController();
  final description = TextEditingController();
  final List<String?> photos = List.filled(4, null);
  late final photoPicker = widget.photoPicker ?? ListingPhotoPicker();
  final totalRooms = TextEditingController();
  String? photoError;
  bool pickingPhoto = false;
  bool publishing = false;
  String? _publishId;
  final locationForm = GlobalKey<FormState>();
  final price = TextEditingController();
  final availableRooms = TextEditingController();
  final address = TextEditingController();
  final contact = TextEditingController();
  final distance = TextEditingController();
  final referenceMap = TextEditingController();
  final Set<String> selectedAmenities = {'WiFi', 'Air Conditioning'};

  String? _basicValidationMessage() {
    final normalizedPhone = contact.text.trim().replaceAll(
      RegExp(r'[\s()\-]'),
      '',
    );
    return name.text.trim().isEmpty
        ? 'Please enter the property name.'
        : description.text.trim().isEmpty
        ? 'Please enter a description.'
        : !RegExp(r'^\+?\d{10,15}$').hasMatch(normalizedPhone)
        ? 'Please enter a valid contact number.'
        : null;
  }

  String? _pricingValidationMessage() {
    final monthlyRent = int.tryParse(price.text.trim());
    final roomTotal = int.tryParse(totalRooms.text.trim());
    final roomAvailable = int.tryParse(availableRooms.text.trim());
    return monthlyRent == null || monthlyRent <= 0
        ? 'Please enter a valid monthly rent.'
        : roomTotal == null || roomTotal <= 0
        ? 'Please enter at least one room.'
        : roomAvailable == null || roomAvailable < 0
        ? 'Please enter a valid available room count.'
        : roomAvailable > roomTotal
        ? 'Available rooms cannot exceed total rooms.'
        : null;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _basicNext() {
    final message = _basicValidationMessage();
    if (message != null) {
      _showValidationMessage(message);
      return;
    }
    widget.onNext();
  }

  void _refresh(VoidCallback update) => setState(update);

  @override
  void initState() {
    super.initState();
    _recoverListingPhoto();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    totalRooms.dispose();
    price.dispose();
    availableRooms.dispose();
    address.dispose();
    contact.dispose();
    distance.dispose();
    referenceMap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.step == 0) return _firstStep();
    return _laterSteps();
  }

  Widget _nextButton() => SizedBox(
    height: widget.step == 0 ? null : 29,
    width: double.infinity,
    child: FilledButton(
      onPressed: _basicNext,
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        minimumSize: widget.step == 0 ? const Size(0, 48) : null,
        padding: widget.step == 0
            ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
            : EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.step == 0 ? 12 : 7),
        ),
      ),
      child: Text(
        widget.step == 3 ? 'Publish Listing' : 'Next',
        style: TextStyle(
          fontSize: widget.step == 0 ? 13 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _firstStep() => ColoredBox(
    color: canvas,
    child: Column(
      children: [
        _roomHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 44),
                Text(
                  'Step ${widget.step + 1} of 4',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: i <= widget.step ? blue : line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _basicInformation(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _basicInformation() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add Room',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Basic Information',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.6, color: muted),
        ),
        const SizedBox(height: 27),
        _roomLabel('Property Name *'),
        _roomField(
          controller: name,
          hint: 'Cozy Student Room near Campus',
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 25),
        _roomLabel('Description *'),
        _roomField(
          controller: description,
          hint: 'Describe the room, facilities, and nearby amenities...',
          multiline: true,
        ),
        const SizedBox(height: 25),
        _roomLabel('Contact Number *'),
        _roomField(
          controller: contact,
          hint: '09171234567',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE9F1FE)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  backgroundColor: paleBlue,
                  foregroundColor: ink,
                  side: BorderSide.none,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _nextButton()),
          ],
        ),
      ],
    ),
  );

  Widget _roomLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4.5),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );

  Widget _roomField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool multiline = false,
    TextInputType? keyboardType,
  }) => Builder(
    builder: (context) => SizedBox(
      height:
          (multiline ? 108 : 48) *
          (MediaQuery.textScalerOf(context).scale(15) / 15).clamp(
            1,
            double.infinity,
          ),
      child: TextFieldBox(
        controller: controller,
        hint: hint,
        maxLines: multiline ? 3 : 1,
        prefixIcon: icon,
        keyboardType: keyboardType,
        fillColor: const Color(0xFFEFF4FF),
        borderColor: Colors.transparent,
        borderRadius: 12,
        prefixIconSize: 20,
        prefixIconColor: muted,
        hintColor: muted,
        textFontSize: 12,
        hintFontSize: 11,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: multiline ? 17 : 13,
        ),
        prefixIconConstraints: icon == null
            ? null
            : const BoxConstraints(minWidth: 48),
      ),
    ),
  );

  Widget _roomHeader() => BrandHeader(onProfile: widget.onProfile);
}

mixin _AddRoomFlow on State<StayNearApp> {
  int wizardStep = 0;
  UserProfile? get activeUser;
  ListingStore get listingStore;
  void go(AppPage next);
  void _openAddRoom() {
    setState(() => wizardStep = 0);
    go(AppPage.roomWizard);
  }

  Widget _buildAddRoom(BuildContext context) {
    return RoomWizard(
      step: wizardStep,
      onBack: () => go(AppPage.landlordDashboard),
      onProfile: () => go(AppPage.profile),
      onNext: () {
        if (wizardStep < 3) {
          setState(() => wizardStep++);
        }
      },
      onPrevious: () => setState(() => wizardStep--),
      onPublish: (listing) async {
        final owner = activeUser;
        if (owner == null || owner.role != UserRole.landlord) {
          throw StateError('Please sign in as a Landowner.');
        }
        await listingStore.publish(listing.copyWith(ownerId: owner.id));
      },
      onPublished: () {
        if (!mounted) return;
        setState(() {
          wizardStep = 0;
        });
        go(AppPage.landlordDashboard);
      },
    );
  }
}
