part of '../main.dart';

class LandownerEditProfilePage extends StatefulWidget {
  const LandownerEditProfilePage({
    required this.user,
    required this.onBack,
    required this.onSave,
    this.photoPicker,
    super.key,
  });
  final UserProfile user;
  final VoidCallback onBack;
  final Future<void> Function(UserProfile) onSave;
  final ProfilePhotoPicker? photoPicker;

  @override
  State<LandownerEditProfilePage> createState() =>
      _LandownerEditProfilePageState();
}

class _LandownerEditProfilePageState extends State<LandownerEditProfilePage> {
  static const _blue = Color(0xFF1259DD);
  static const _ink = Color(0xFF252A31);
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.contact);
  late final _email = TextEditingController(text: widget.user.email);
  late final _address = TextEditingController(text: widget.user.address);
  late final _picker = widget.photoPicker ?? ProfilePhotoPicker();
  String? _draftPhoto, _error;
  bool _saving = false, _picking = false;

  @override
  void initState() {
    super.initState();
    _recoverPhoto();
  }

  Future<void> _recoverPhoto() async {
    try {
      final photo = await _picker.recover();
      if (mounted && photo != null && _draftPhoto == null && !_saving) {
        setState(() => _draftPhoto = photo);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not recover the selected photo. Please choose it again.',
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant LandownerEditProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A saved-profile read may finish after navigation; never replace a draft.
    if (!_saving &&
        _draftPhoto == null &&
        _name.text == oldWidget.user.fullName &&
        _phone.text == oldWidget.user.contact &&
        _email.text == oldWidget.user.email &&
        _address.text == oldWidget.user.address) {
      _name.text = widget.user.fullName;
      _phone.text = widget.user.contact;
      _email.text = widget.user.email;
      _address.text = widget.user.address;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (_picking || _saving) return;
    setState(() {
      _picking = true;
      _error = null;
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
      if (source == null || !mounted) return;
      final photo = await _picker.pick(source);
      if (mounted && photo != null) setState(() => _draftPhoto = photo);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error.code.toLowerCase().contains('access') ||
                  error.code.toLowerCase().contains('denied')
              ? 'Photo access was denied. Allow access in your device settings and try again.'
              : 'Could not open your photos. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not read that photo. Please choose another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        widget.user.withProfileEdits(
          fullName: _name.text,
          phone: _phone.text,
          email: _email.text,
          address: _address.text,
          photo: _draftPhoto,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = backendMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() {
    if (!_saving) widget.onBack();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: ThemeData(fontFamily: 'Roboto').textTheme
            .apply(bodyColor: _ink, displayColor: _ink),
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
      ),
      child: ColoredBox(
        color: const Color(0xFFF7F8FA),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 72),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x09000000),
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: _saving ? null : _back,
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0F1F3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x09000000),
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFF0F1F5),
                              ),
                            ),
                            child: LandownerProfileAvatar(
                              key: const ValueKey('edit-profile-photo'),
                              source: _draftPhoto ?? widget.user.profilePhoto,
                              size: 104,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _saving || _picking
                                ? null
                                : _changePhoto,
                            child: Text(
                              _picking ? 'Opening photos…' : 'Change Photo',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _field(
                          'FULL NAME',
                          'profile-name',
                          _name,
                          Icons.person_outline,
                          keyboard: TextInputType.name,
                        ),
                        const SizedBox(height: 20),
                        _field(
                          'PHONE NUMBER',
                          'profile-phone',
                          _phone,
                          Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number.';
                            }
                            final digits = value.replaceAll(RegExp(r'\D'), '');
                            if (!RegExp(r'^\+?[0-9\s().-]+$')
                                    .hasMatch(value.trim()) ||
                                digits.length < 7 ||
                                digits.length > 15) {
                              return 'Please enter a valid phone number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _field(
                          'EMAIL ADDRESS',
                          'profile-email',
                          _email,
                          Icons.mail_outline,
                          keyboard: TextInputType.emailAddress,
                          validator: (value) =>
                              value == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value.trim())
                              ? 'Please enter a valid email address.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _field(
                          'ADDRESS',
                          'profile-address',
                          _address,
                          Icons.location_on_outlined,
                          keyboard: TextInputType.streetAddress,
                          multiline: true,
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              key: const ValueKey('profile-error'),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFFB42318),
                              ),
                            ),
                          ),
                        const SizedBox(height: 36),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving ? null : _back,
                                style: _buttonStyle(
                                  const Color(0xFFD2E3FF),
                                  const Color(0xFF132438),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                key: const ValueKey('save-profile'),
                                onPressed: _saving || _picking ? null : _save,
                                style: _buttonStyle(
                                  const Color(0xFF377DF4),
                                  Colors.white,
                                ),
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  ButtonStyle _buttonStyle(Color background, Color foreground) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _field(
    String label,
    String key,
    TextEditingController controller,
    IconData icon, {
    required TextInputType keyboard,
    bool multiline = false,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
          color: Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: multiline ? const Color(0xFFF3F4F6) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: TextFormField(
          key: ValueKey(key),
          controller: controller,
          enabled: !_saving,
          keyboardType: keyboard,
          minLines: multiline ? 2 : 1,
          maxLines: multiline ? 4 : 1,
          textInputAction: multiline
              ? TextInputAction.newline
              : TextInputAction.next,
          textCapitalization: keyboard == TextInputType.name || multiline
              ? TextCapitalization.words
              : TextCapitalization.none,
          autocorrect: keyboard != TextInputType.emailAddress,
          style: const TextStyle(fontSize: 16, color: _ink, height: 1.5),
          validator:
              validator ??
              (value) => value == null || value.trim().isEmpty
                  ? (multiline
                        ? 'Please enter your address.'
                        : 'Please enter your full name.')
                  : null,
          decoration: InputDecoration(
            isDense: true,
            errorMaxLines: 3,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: multiline ? 16 : 13,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                multiline ? 17 : 13,
                12,
                multiline ? 39 : 13,
              ),
              child: Icon(icon, size: 21, color: const Color(0xFF4B5563)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _blue),
            ),
          ),
        ),
      ),
    ],
  );
}
