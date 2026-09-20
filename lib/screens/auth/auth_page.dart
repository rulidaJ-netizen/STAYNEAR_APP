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
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final middleName = TextEditingController();
  final contact = TextEditingController();
  final address = TextEditingController();
  final birthday = TextEditingController();
  final confirm = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();
  final registrationFormKey = GlobalKey<FormState>();
  bool showPassword = false;
  String? gender;
  late String error = widget.initialError ?? '';
  bool _busy = false;
  final nameFormatter = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'));
  final middleInitialFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final value = newValue.text.toUpperCase();
    if (value.isEmpty || RegExp(r'^[A-Z]\.?$').hasMatch(value)) {
      return newValue.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    return oldValue;
  });

  void handleRoleChanged(UserRole nextRole) {
    firstName.clear();
    lastName.clear();
    middleName.clear();
    email.clear();
    contact.clear();
    address.clear();
    birthday.clear();
    password.clear();
    confirm.clear();
    gender = null;
    error = '';
    loginFormKey.currentState?.reset();
    registrationFormKey.currentState?.reset();
    widget.onRoleChanged(nextRole);
    setState(() {});
  }

  String? firstNameValidator(String? value) {
    final name = value?.trim() ?? '';
    return name.isEmpty || !RegExp(r'^[a-zA-Z ]+$').hasMatch(name)
        ? 'Invalid First Name'
        : null;
  }

  String? lastNameValidator(String? value) {
    final name = value?.trim() ?? '';
    return name.isEmpty || !RegExp(r'^[a-zA-Z ]+$').hasMatch(name)
        ? 'Invalid Last Name'
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
    if (!RegExp(r'^09\d{9}$').hasMatch(contactValue)) {
      return 'Invalid Contact Number';
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

  String? middleInitialValidator(String? value) {
    if (!RegExp(r'^[A-Z]\.$').hasMatch(value?.trim() ?? '')) {
      return 'Invalid Middle Initial';
    }
    return null;
  }

  String? birthdayValidator(String? value) =>
      value?.trim().isEmpty ?? true ? 'Please select your Birthday' : null;

  String? addressValidator(String? value) =>
      value?.trim().isEmpty ?? true ? 'Please enter your Address' : null;

  Future<void> pickBirthday() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (selected != null) {
      birthday.text =
          '${selected.month.toString().padLeft(2, '0')}/'
          '${selected.day.toString().padLeft(2, '0')}/'
          '${selected.year}';
    }
  }

  Widget genderField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Gender',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
      ),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        initialValue: gender,
        isExpanded: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.person_outline,
            size: 18,
            color: Color(0xFF9FA9B8),
          ),
          hintText: 'Select Gender',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA5AFBC)),
          filled: true,
          fillColor: const Color(0xFFF0F4F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
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
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
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
    firstName.dispose();
    lastName.dispose();
    middleName.dispose();
    contact.dispose();
    address.dispose();
    birthday.dispose();
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
        await widget.onRegister(
          UserProfile(
            firstName: firstName.text.trim(),
            middleName: middleName.text.trim(),
            lastName: lastName.text.trim(),
            email: email.text.trim(),
            birthday: birthday.text.trim(),
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
    showText: showPassword,
    onToggle: obscure
        ? () => setState(() => showPassword = !showPassword)
        : null,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: CardShell(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Form(
          key: registrationFormKey,
          child: Column(
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Fill in your details to get started',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 34),
              Segmented(
                labels: const ['Boarders', 'Landowner'],
                selected: widget.role == UserRole.landlord ? 1 : 0,
                onChanged: (i) => handleRoleChanged(
                  i == 1 ? UserRole.landlord : UserRole.boarder,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: field(
                      'First Name',
                      firstName,
                      validator: firstNameValidator,
                      inputFormatters: [nameFormatter],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: field(
                      'Last Name',
                      lastName,
                      validator: lastNameValidator,
                      inputFormatters: [nameFormatter],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: field(
                      'Middle Name',
                      middleName,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: field(
                      'Email Address',
                      email,
                      icon: Icons.mail_outline,
                      validator: emailValidator,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: field(
                      'Birthday',
                      birthday,
                      icon: Icons.calendar_today_outlined,
                      hint: 'mm/dd/yyyy',
                      validator: birthdayValidator,
                      readOnly: true,
                      onTap: pickBirthday,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: genderField()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: field(
                      'Contact No.',
                      contact,
                      icon: Icons.phone_outlined,
                      validator: contactValidator,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: field(
                      'Address',
                      address,
                      icon: Icons.location_on_outlined,
                      validator: addressValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: field(
                      'Create Password',
                      password,
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: passwordValidator,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: field(
                      'Confirm Password',
                      confirm,
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: confirmPasswordValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: submit,
                  child: const Text(
                    'Register',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 13, color: muted),
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
                      style: TextStyle(fontSize: 13, color: blue),
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
