// ignore_for_file: file_names
part of '../main.dart';

class EditListingPage extends StatefulWidget {
  const EditListingPage({
    required this.listing,
    required this.onBack,
    required this.onProfile,
    required this.onSave,
    this.photoPicker,
    super.key,
  });
  final Listing listing;
  final VoidCallback onBack, onProfile;
  final FutureOr<void> Function(Listing) onSave;
  final ProfilePhotoPicker? photoPicker;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.listing.title);
  late final _price = TextEditingController(
    text: 'PHP ${widget.listing.formattedPrice}',
  );
  late final _rooms = TextEditingController(
    text: '${widget.listing.availableRooms}',
  );
  late final _address = TextEditingController(text: widget.listing.address);
  late final _contact = TextEditingController(text: widget.listing.contact);
  late final _description = TextEditingController(
    text: widget.listing.description,
  );
  late final _picker = widget.photoPicker ?? ListingPhotoPicker();
  late final List<String?> _photos = List.generate(
    4,
    (index) => index < widget.listing.photos.length
        ? widget.listing.photos[index]
        : null,
  );
  late bool _available = widget.listing.available;
  bool _pickingPhoto = false, _saving = false;
  String? _photoError, _saveError;

  @override
  void initState() {
    super.initState();
    _recoverPhoto();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _price,
      _rooms,
      _address,
      _contact,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _recoverPhoto() async {
    _pickingPhoto = true;
    try {
      final photo = await _picker.recover();
      if (!mounted || photo == null) return;
      final slot = _photos.indexOf(null);
      if (slot >= 0) setState(() => _photos[slot] = photo);
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'Could not recover the photo. Please choose it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _choosePhoto(int slot) async {
    if (_pickingPhoto || _saving) return;
    setState(() {
      _pickingPhoto = true;
      _photoError = null;
    });
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_picker.supportsCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ListTile(
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
      if (!mounted || source == null) return;
      final photo = await _picker.pick(source);
      if (mounted && photo != null) setState(() => _photos[slot] = photo);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _photoError = 'Could not access your photos. Check photo permissions and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'Could not read this photo. Please choose another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  int? _parsedPrice(String value) {
    final number = value.trim().replaceFirst(
      RegExp(r'^PHP\s*', caseSensitive: false),
      '',
    );
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)$').hasMatch(number)) return null;
    return int.tryParse(number.replaceAll(',', ''));
  }

  Future<void> _save() async {
    if (_saving || _pickingPhoto) return;
    if (!_form.currentState!.validate()) {
      setState(() => _saveError = 'Please check the highlighted fields.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(
        widget.listing.copyWith(
          title: _name.text.trim(),
          price: _parsedPrice(_price.text)!,
          availableRooms: int.parse(_rooms.text.trim()),
          available: _available,
          address: _address.text.trim(),
          contact: _contact.text.trim(),
          description: _description.text.trim(),
          photos: _photos.whereType<String>().toList(),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = 'Could not save this listing. Your changes are still here; please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: canvas,
    child: Column(
      children: [
        BrandHeader(onProfile: widget.onProfile),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Listing',
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Update property details and availability.',
                  style: TextStyle(fontSize: 12, height: 1.6, color: muted),
                ),
                const SizedBox(height: 26),
                _card(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (var index = 0; index < 4; index++)
                              SizedBox(
                                width: (constraints.maxWidth - 16) / 2,
                                child: AspectRatio(
                                  aspectRatio: 1.12,
                                  child: _photoSlot(index),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_pickingPhoto)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Loading photo…',
                            style: TextStyle(fontSize: 13, color: muted),
                          ),
                        ),
                      if (_photoError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _photoError!,
                            style: const TextStyle(
                              color: Color(0xFFBA1A1A),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listing Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RadioGroup<bool>(
                        groupValue: _available,
                        onChanged: (value) {
                          if (value != null && !_saving) {
                            setState(() => _available = value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final available in [true, false])
                              RadioListTile<bool>(
                                visualDensity: const VisualDensity(
                                  vertical: -2,
                                ),
                                fillColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                      ? const Color(0xFF004BCC)
                                      : const Color(0xFFC2C6D6),
                                ),
                                value: available,
                                enabled: !_saving,
                                activeColor: const Color(0xFF004BCC),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  available ? 'Available' : 'Unavailable',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _card(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(
                          'Property Name',
                          _name,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a property name.'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _field(
                          'Monthly Price',
                          _price,
                          keyboard: TextInputType.number,
                          validator: (value) =>
                              (_parsedPrice(value ?? '') ?? 0) <= 0
                              ? 'Enter a monthly price greater than zero.'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _field(
                          'Available Rooms',
                          _rooms,
                          keyboard: TextInputType.number,
                          validator: (value) {
                            final rooms = int.tryParse(value?.trim() ?? '');
                            if (rooms == null || rooms < 0) {
                              return 'Enter zero or more rooms.';
                            }
                            if (widget.listing.totalRooms > 0 &&
                                rooms > widget.listing.totalRooms) {
                              return 'Cannot exceed ${widget.listing.totalRooms} total rooms.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _field(
                          'Location',
                          _address,
                          icon: Icons.location_on_outlined,
                          keyboard: TextInputType.streetAddress,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter the full address.'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _field(
                          'Contact Number',
                          _contact,
                          keyboard: TextInputType.phone,
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (phone.isEmpty) return null;
                            final digits = phone.replaceAll(RegExp(r'\D'), '');
                            return RegExp(r'^\+?[\d\s()\-]+$')
                                        .hasMatch(phone) &&
                                    digits.length >= 7 &&
                                    digits.length <= 15
                                ? null
                                : 'Enter a valid contact number.';
                          },
                        ),
                        const SizedBox(height: 24),
                        _field(
                          'Description',
                          _description,
                          optional: true,
                          maxLines: 4,
                          keyboard: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width >= 360 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 20
                ? 64
                : 16,
            20,
            16,
            16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFD8E0EE))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(
                      color: Color(0xFFBA1A1A),
                      fontSize: 13,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : widget.onBack,
                      style: _buttonStyle(const Color(0xFFD3E4FE), _ownerInk),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _pickingPhoto ? null : _save,
                      style: _buttonStyle(
                        const Color(0xFF3B82F6),
                        Colors.white,
                      ),
                      child: Text(
                        _saving ? 'Saving…' : 'Save',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
  );

  ButtonStyle _buttonStyle(Color background, Color foreground) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _card({required Widget child, required EdgeInsets padding}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAED)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(type: MaterialType.transparency, child: child),
      );

  Widget _photoSlot(int index) {
    final source = _photos[index];
    if (source != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: 'Replace Photo ${index + 1}',
            child: GestureDetector(
              onTap: _saving || _pickingPhoto
                  ? null
                  : () => _choosePhoto(index),
              child: Photo(
                url: source,
                height: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: IconButton(
              tooltip: 'Remove Photo ${index + 1}',
              onPressed: _saving || _pickingPhoto
                  ? null
                  : () => setState(() => _photos[index] = null),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x9950555D),
                foregroundColor: Colors.white,
                minimumSize: const Size(28, 28),
                padding: const EdgeInsets.all(4),
              ),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      );
    }
    return CustomPaint(
      foregroundPainter: _PhotoSlotBorder(),
      child: Material(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _saving || _pickingPhoto ? null : () => _choosePhoto(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_upload_outlined, size: 28, color: muted),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  'Photo ${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    IconData? icon,
    int maxLines = 1,
    bool optional = false,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
          if (optional)
            const Text(
              'Optional',
              style: TextStyle(fontSize: 11, color: muted),
            ),
        ],
      ),
      const SizedBox(height: 5),
      TextFormField(
        key: ValueKey('edit-$label'),
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 12, height: 1.45, color: ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF7F9FB),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          prefixIcon: icon == null ? null : Icon(icon, size: 19, color: muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          errorMaxLines: 3,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _ownerBlue, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
