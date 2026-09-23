part of '../../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.login,
    required this.role,
    required this.onRoleChanged,
    required this.onLoginChanged,
    required this.onRegister,
    required this.onLogin,
    this.onResetPassword,
    this.initialError,
    super.key,
  });
  final bool login;
  final UserRole role;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<bool> onLoginChanged;
  final Future<void> Function(UserProfile) onRegister;
  final Future<void> Function(String)? onResetPassword;
  final String? initialError;
  final Future<bool> Function(String email, String password, UserRole role)
  onLogin;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  final contact = TextEditingController();
  final address = TextEditingController();
  final age = TextEditingController();
  final confirm = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();
  final registrationFormKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool showConfirmPassword = false;
  String? gender;
  late String error = widget.initialError ?? '';
  bool _busy = false;
  final capitalizeFirstLetterFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final firstLetter = RegExp(r'[a-zA-Z]').firstMatch(newValue.text);
    if (firstLetter == null) return newValue;
    final index = firstLetter.start;
    final capitalized = newValue.text[index].toUpperCase();
    if (newValue.text[index] == capitalized) return newValue;
    return newValue.copyWith(
      text: newValue.text.replaceRange(index, index + 1, capitalized),
    );
  });
  final capitalizeNameFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final capitalized = newValue.text.replaceAllMapped(
      RegExp(r'(^|\s)[a-z]'),
      (match) => match.group(0)!.toUpperCase(),
    );
    return capitalized == newValue.text
        ? newValue
        : newValue.copyWith(text: capitalized);
  });

  void handleRoleChanged(UserRole nextRole) {
    fullName.clear();
    email.clear();
    contact.clear();
    address.clear();
    age.clear();
    password.clear();
    confirm.clear();
    gender = null;
    error = '';
    loginFormKey.currentState?.reset();
    registrationFormKey.currentState?.reset();
    widget.onRoleChanged(nextRole);
    setState(() {});
  }

  String? fullNameValidator(String? value) {
    final name = value?.trim() ?? '';
    return name.isEmpty || !RegExp(r'^[a-zA-Z ]+$').hasMatch(name)
        ? 'Invalid Full Name'
        : null;
  }

  String? emailValidator(String? value) {
    final emailValue = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailValue)) {
      return 'Invalid Email Address';
    }
    return null;
  }

  String? contactValidator(String? value) {
    final contactValue = value?.trim() ?? '';
    if (!RegExp(r'^\d{11}$').hasMatch(contactValue)) {
      return 'Enter a valid contact number.';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value != password.text) return 'Passwords do not match';
    return null;
  }

  String? ageValidator(String? value) {
    final parsedAge = int.tryParse(value?.trim() ?? '');
    if (parsedAge == null || parsedAge < 1 || parsedAge > 125) {
      return 'Enter a valid Age';
    }
    return null;
  }

  String? addressValidator(String? value) {
    final addressValue = value?.trim() ?? '';
    if (addressValue.isEmpty) return 'Please enter your Address';
    if (!RegExp(r'[a-zA-Z]').hasMatch(addressValue)) {
      return 'Invalid Address';
    }
    return null;
  }

  Widget registrationGenderField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Gender',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink),
      ),
      const SizedBox(height: 9),
      DropdownButtonFormField<String>(
        initialValue: gender,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: ink),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 24,
          color: Color(0xFF6E7B91),
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.person_outline,
            size: 24,
            color: Color(0xFF98A8BF),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 19,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: blue, width: 1.25),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          errorMaxLines: 2,
          errorStyle: const TextStyle(
            fontSize: 11,
            height: 1.1,
            color: Colors.red,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Male',
            child: Text('Male', style: TextStyle(fontSize: 14)),
          ),
          DropdownMenuItem(
            value: 'Female',
            child: Text('Female', style: TextStyle(fontSize: 14)),
          ),
        ],
        onChanged: (value) => setState(() => gender = value),
        validator: (value) => value == null ? 'Please select a Gender' : null,
      ),
    ],
  );

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    contact.dispose();
    address.dispose();
    age.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_busy) return;
    if (!widget.login &&
        !(registrationFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Invalid email or password');
      return;
    }
    setState(() {
      _busy = true;
      error = '';
    });
    try {
      if (widget.login) {
        final success = await widget.onLogin(
          email.text,
          password.text,
          widget.role,
        );
        if (!success && mounted) {
          setState(() => error = 'Invalid email or password');
        }
      } else {
        final nameParts = fullName.text.trim().split(RegExp(r'\s+'));
        final birthYear = DateTime.now().year - int.parse(age.text.trim());
        await widget.onRegister(
          UserProfile(
            firstName: nameParts.first,
            middleName: nameParts.length > 2
                ? nameParts.sublist(1, nameParts.length - 1).join(' ')
                : '',
            lastName: nameParts.length > 1 ? nameParts.last : '',
            email: email.text.trim(),
            birthday: '01/01/$birthYear',
            gender: gender!,
            contact: contact.text.trim(),
            address: address.text.trim(),
            password: password.text,
            role: widget.role,
          ),
        );
        if (mounted) {
          password.clear();
          confirm.clear();
        }
      }
    } catch (failure) {
      if (mounted) {
        setState(() => error = backendMessage(failure));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_busy) return;
    if (emailValidator(email.text) != null) {
      setState(
        () => error = 'Enter your email address to reset your password.',
      );
      return;
    }
    setState(() {
      _busy = true;
      error = '';
    });
    try {
      final reset = widget.onResetPassword;
      if (reset == null) {
        throw StateError('Password reset is not configured for this screen.');
      }
      await reset(email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Please check your email.'),
          ),
        );
      }
    } catch (failure) {
      if (mounted) setState(() => error = backendMessage(failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    bool obscure = false,
    bool showLabel = true,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLength,
    ValueChanged<String>? onChanged,
    bool? showText,
    VoidCallback? onToggle,
  }) => AuthField(
    label: label,
    controller: controller,
    icon: icon,
    hint: hint ?? label,
    obscure: obscure,
    showLabel: showLabel,
    validator: validator,
    inputFormatters: inputFormatters,
    keyboardType: keyboardType,
    suffixIcon: suffixIcon,
    readOnly: readOnly,
    onTap: onTap,
    maxLength: maxLength,
    onChanged: onChanged,
    showText: showText ?? showPassword,
    onToggle: obscure
        ? onToggle ?? () => setState(() => showPassword = !showPassword)
        : null,
  );

  Widget registrationField(
    String label,
    TextEditingController controller, {
    required IconData icon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool obscure = false,
    bool showText = false,
    VoidCallback? onToggle,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      const SizedBox(height: 9),
      TextFormField(
        controller: controller,
        obscureText: obscure && !showText,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: ink),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 24, color: const Color(0xFF98A8BF)),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          suffixIcon: onToggle == null
              ? null
              : IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    showText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 24,
                    color: const Color(0xFF98A8BF),
                  ),
                ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 19,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: blue, width: 1.25),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          errorMaxLines: 2,
          errorStyle: const TextStyle(
            fontSize: 11,
            height: 1.1,
            color: Colors.red,
          ),
        ),
      ),
    ],
  );

  Widget registrationRoleSelector() => Container(
    width: double.infinity,
    height: 56,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        for (final option in const [
          (label: 'Boarders', role: UserRole.boarder),
          (label: 'Landowner', role: UserRole.landlord),
        ])
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => handleRoleChanged(option.role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.role == option.role
                      ? const Color(0xFF2F6FED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: widget.role == option.role
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.role == option.role
                        ? Colors.white
                        : const Color(0xFF6E819F),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.login) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: CardShell(
          padding: const EdgeInsets.fromLTRB(32, 54, 32, 34),
          child: Form(
            key: loginFormKey,
            child: Column(
              children: [
                const Text(
                  'StayNear',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 15, color: Color(0xFF596174)),
                ),
                const SizedBox(height: 34),
                Segmented(
                  labels: const ['Boarder', 'Landowner'],
                  selected: widget.role == UserRole.landlord ? 1 : 0,
                  onChanged: (i) => handleRoleChanged(
                    i == 1 ? UserRole.landlord : UserRole.boarder,
                  ),
                ),
                const SizedBox(height: 28),
                field(
                  'Email Address',
                  email,
                  icon: Icons.mail_outline,
                  showLabel: false,
                  onChanged: (_) {
                    if (error.isNotEmpty) setState(() => error = '');
                  },
                ),
                const SizedBox(height: 14),
                field(
                  'Password',
                  password,
                  icon: Icons.lock_outline,
                  obscure: true,
                  showLabel: false,
                  onChanged: (_) {
                    if (error.isNotEmpty) setState(() => error = '');
                  },
                ),
                if (error.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12, color: blue),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: submit,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Login'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                    TextButton(
                      onPressed: () => widget.onLoginChanged(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Register here',
                        style: TextStyle(fontSize: 14, color: blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 34),
        child: Form(
          key: registrationFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10182B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fill in your details to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6E819F),
                ),
              ),
              const SizedBox(height: 30),
              registrationRoleSelector(),
              const SizedBox(height: 28),
              registrationField(
                'Full Name',
                fullName,
                icon: Icons.person_outline,
                validator: fullNameValidator,
                inputFormatters: [capitalizeNameFormatter],
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 22),
              registrationField(
                'Email address',
                email,
                icon: Icons.mail_outline,
                validator: emailValidator,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 22),
              registrationField(
                'Contact No.',
                contact,
                icon: Icons.phone_outlined,
                validator: contactValidator,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              registrationField(
                'Address',
                address,
                icon: Icons.location_on_outlined,
                validator: addressValidator,
                inputFormatters: [capitalizeFirstLetterFormatter],
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: registrationField(
                      'Age',
                      age,
                      icon: Icons.person_outline,
                      validator: ageValidator,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: registrationGenderField()),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: registrationField(
                      'Create Password',
                      password,
                      icon: Icons.lock_outline,
                      obscure: true,
                      showText: showPassword,
                      validator: passwordValidator,
                      onToggle: () =>
                          setState(() => showPassword = !showPassword),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: registrationField(
                      'Confirm Password',
                      confirm,
                      icon: Icons.lock_outline,
                      obscure: true,
                      showText: showConfirmPassword,
                      validator: confirmPasswordValidator,
                      onToggle: () => setState(
                        () => showConfirmPassword = !showConfirmPassword,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              SizedBox(
                height: 60,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6FED),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0x552F6FED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: submit,
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6E819F)),
                  ),
                  TextButton(
                    onPressed: () => widget.onLoginChanged(true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Login here',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2F6FED),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
