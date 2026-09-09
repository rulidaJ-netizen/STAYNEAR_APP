part of '../../main.dart';

class RoomWizard extends StatefulWidget {
  const RoomWizard({
    required this.step,
    required this.onBack,
    required this.onProfile,
    required this.onNext,
    required this.onPrevious,
    required this.onPublish,
    super.key,
  });
  final int step;
  final VoidCallback onBack, onProfile, onNext, onPrevious;
  final ValueChanged<Listing> onPublish;
  @override
  State<RoomWizard> createState() => _RoomWizardState();
}

class _RoomWizardState extends State<RoomWizard> {
  final name = TextEditingController();
  final description = TextEditingController();
  final image = TextEditingController();
  final price = TextEditingController();
  final availableRooms = TextEditingController();
  final address = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    image.dispose();
    price.dispose();
    availableRooms.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Add Room',
      'Upload Photos',
      'Pricing & Availability',
      'Location Details',
    ];
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: line)),
          ),
          child: BrandHeader(onProfile: widget.onProfile),
        ),
        if (widget.step == 0) _progressBars() else _stepLabel(),
        if (widget.step == 0) _stepLabel() else _progressBars(),
        Expanded(
          child: SingleChildScrollView(
            padding: widget.step == 0
                ? const EdgeInsets.fromLTRB(8, 10, 8, 18)
                : const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: _content(titles[widget.step]),
          ),
        ),
      ],
    );
  }

  Widget _stepLabel() => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'Step ${widget.step + 1} of 4',
      style: const TextStyle(fontSize: 9, color: muted),
    ),
  );

  Widget _progressBars() => Padding(
    padding: EdgeInsets.fromLTRB(
      widget.step == 0 ? 0 : 15,
      10,
      widget.step == 0 ? 0 : 15,
      2,
    ),
    child: Center(
      child: SizedBox(
        width: widget.step == 0 ? 170 : double.infinity,
        child: Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: i <= widget.step ? blue : paleBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _nextButton() => SizedBox(
    height: 29,
    width: double.infinity,
    child: FilledButton(
      onPressed: () {
        if (widget.step < 3) {
          widget.onNext();
          return;
        }
        final rooms = int.tryParse(availableRooms.text.trim()) ?? 0;
        widget.onPublish(
          Listing(
            title: name.text.trim().isEmpty
                ? 'Untitled listing'
                : name.text.trim(),
            address: address.text.trim(),
            price:
                int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0,
            image: image.text.trim().isEmpty ? null : image.text.trim(),
            availableRooms: rooms,
            totalRooms: rooms,
          ),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(
        widget.step == 3 ? 'Publish Listing' : 'Next',
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _wizardCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _requiredLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  );

  Widget _wizardLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );

  Widget _wizardField({
    TextEditingController? controller,
    required String hint,
    double height = 28,
    int maxLines = 1,
    IconData? icon,
  }) => SizedBox(
    height: height,
    child: TextFieldBox(
      controller: controller,
      hint: hint,
      maxLines: maxLines,
      prefixIcon: icon,
      fillColor: paleBlue,
      borderColor: Colors.transparent,
      borderRadius: 8,
      prefixIconSize: 12,
      prefixIconColor: const Color(0xFFB7C3D6),
      hintColor: const Color(0xFFC5CFDF),
      textFontSize: 8,
      hintFontSize: 8,
      contentPadding: maxLines == 1
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
          : const EdgeInsets.fromLTRB(8, 7, 8, 7),
      prefixIconConstraints: icon == null
          ? null
          : const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
              maxWidth: 28,
              maxHeight: 28,
            ),
    ),
  );

  Widget _previousButton() => SizedBox(
    height: 29,
    width: double.infinity,
    child: OutlinedButton(
      onPressed: widget.onPrevious,
      style: OutlinedButton.styleFrom(
        backgroundColor: paleBlue,
        foregroundColor: ink,
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: const Text(
        'Previous',
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _wizardActions({bool expanded = false}) => Row(
    children: [
      if (expanded)
        Expanded(child: _previousButton())
      else
        SizedBox(width: 63, child: _previousButton()),
      if (expanded) const SizedBox(width: 9) else const Spacer(),
      if (expanded)
        Expanded(child: _nextButton())
      else
        SizedBox(width: 58, child: _nextButton()),
    ],
  );

  Widget _photoPreview() => SizedBox(
    height: 85,
    child: Stack(
      children: [
        Photo(url: image.text.trim(), height: 85),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF64748B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 9),
          ),
        ),
      ],
    ),
  );

  Widget _amenityChip(String label, {bool selected = false}) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 8, color: ink)),
    selected: selected,
    onSelected: (_) {},
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
    labelPadding: EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    backgroundColor: paleBlue,
    selectedColor: const Color(0xFFEAF2FF),
    side: const BorderSide(color: line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _content(String title) {
    if (title == 'Upload Photos') {
      return _wizardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Photos',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add high-quality photos to attract more students',
              style: TextStyle(fontSize: 8, color: muted),
            ),
            const SizedBox(height: 16),
            _requiredLabel('Property Photos'),
            Row(
              children: [
                Expanded(child: _photoPreview()),
                const SizedBox(width: 8),
                const Expanded(child: UploadTile(label: 'Photo 2', height: 85)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: UploadTile(label: 'Photo 3', height: 85)),
                SizedBox(width: 8),
                Expanded(child: UploadTile(label: 'Photo 4', height: 85)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Upload at least 1 high-quality photo of the room',
                    style: TextStyle(fontSize: 8, color: muted),
                  ),
                ),
                const Text(
                  'Selected: 1/4',
                  style: TextStyle(fontSize: 8, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 19),
            _wizardActions(expanded: true),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: blue, size: 14),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Photo Requirements',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Horizontal orientation preferred\n'
                          'Minimum resolution: 1024x768\n'
                          'Well-lit, natural lighting\n'
                          'No text or watermarks',
                          style: TextStyle(fontSize: 8, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (title == 'Pricing & Availability') {
      return _wizardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Availability',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set the monthly rent, room inventory, and\namenities students can expect from your listing.',
              style: TextStyle(fontSize: 8, color: muted),
            ),
            const SizedBox(height: 15),
            _requiredLabel('Monthly Rent (PHP)'),
            _wizardField(controller: price, hint: '5000', height: 38),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Total Rooms'),
                      _wizardField(hint: '0'),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Available Rooms'),
                      _wizardField(controller: availableRooms, hint: '0'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Amenities',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _amenityChip('WiFi', selected: true),
                _amenityChip('Air Conditioning', selected: true),
                _amenityChip('Study Desk'),
                _amenityChip('Shared Kitchen'),
                _amenityChip('Private Bathroom'),
                _amenityChip('CCTV'),
                _amenityChip('Laundry Area'),
                _amenityChip('Parking'),
                _amenityChip('Balcony'),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: line),
            const SizedBox(height: 14),
            _wizardActions(),
          ],
        ),
      );
    }
    if (title == 'Location Details') {
      return _wizardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Help students find your property with accurate\naddress and map details.',
              style: TextStyle(fontSize: 8, color: muted),
            ),
            const SizedBox(height: 15),
            _requiredLabel('Full Address'),
            _wizardField(controller: address, hint: 'Barangay, Municipality, City'),
            const SizedBox(height: 14),
            _requiredLabel('Distance from University'),
            _wizardField(hint: 'Enter distance information'),
            const SizedBox(height: 14),
            _wizardLabel('Reference Map'),
            _wizardField(hint: 'Paste a Google Maps link'),
            const SizedBox(height: 27),
            const Divider(height: 1, color: line),
            const SizedBox(height: 14),
            _wizardActions(),
          ],
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 227),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 17, 13, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          const Text(
            'Add Room',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Basic Information',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: muted),
          ),
          const SizedBox(height: 18),
          _roomLabel('Property Name *'),
          SizedBox(
            height: 28,
            child: TextFieldBox(
              controller: name,
              hint: 'Cozy Student Room near Campus',
              prefixIcon: Icons.home_outlined,
              fillColor: paleBlue,
              borderRadius: 8,
              borderColor: Colors.transparent,
              prefixIconSize: 12,
              prefixIconColor: const Color(0xFFB7C3D6),
              hintColor: const Color(0xFFC5CFDF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              textFontSize: 8,
              hintFontSize: 8,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
                maxWidth: 28,
                maxHeight: 28,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _roomLabel('Description *'),
          SizedBox(
            height: 64,
            child: TextFieldBox(
              controller: description,
              hint: 'Describe the room, facilities, and nearby amenities...',
              maxLines: 3,
              prefixIcon: Icons.notes_outlined,
              fillColor: paleBlue,
              borderRadius: 8,
              borderColor: Colors.transparent,
              prefixIconSize: 12,
              prefixIconColor: const Color(0xFFB7C3D6),
              hintColor: const Color(0xFFC5CFDF),
              contentPadding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              textFontSize: 8,
              hintFontSize: 8,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
                maxWidth: 28,
                maxHeight: 28,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _roomLabel('Contact Number *'),
          SizedBox(
            height: 28,
            child: TextFieldBox(
              hint: '09171234567',
              prefixIcon: Icons.phone_outlined,
              fillColor: paleBlue,
              borderRadius: 8,
              borderColor: Colors.transparent,
              prefixIconSize: 12,
              prefixIconColor: const Color(0xFFB7C3D6),
              hintColor: const Color(0xFFC5CFDF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              textFontSize: 8,
              hintFontSize: 8,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
                maxWidth: 28,
                maxHeight: 28,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: line),
          const SizedBox(height: 19),
          _nextButton(),
          const SizedBox(height: 7),
          SizedBox(
            height: 29,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                backgroundColor: paleBlue,
                foregroundColor: ink,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _roomLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}

class UploadTile extends StatelessWidget {
  const UploadTile({required this.label, this.height = 112, super.key});
  final String label;
  final double height;
  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedBorderPainter(),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.file_upload_outlined, color: muted, size: 15),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 8, color: muted)),
        ],
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBECBE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(7),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + 4 < metric.length
            ? distance + 4
            : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
