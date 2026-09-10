part of '../../main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.user,
    required this.onEdit,
    required this.onLogout,
    required this.onHome,
    required this.onFavorites,
    super.key,
  });
  final UserProfile? user;
  final VoidCallback onEdit, onLogout, onHome, onFavorites;
  @override
  Widget build(BuildContext context) {
    final profile = user;
    final boarder = profile?.role == UserRole.boarder;
    return Column(
      children: [
        TopBar(
          title: 'Profile',
          onBack: onHome,
          action: const SizedBox.shrink(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: CardShell(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: NetworkImage(
                      boarder ? boarderAvatarImage : landownerAvatarImage,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    profile?.fullName ?? 'Profile',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      profile?.roleLabel ?? 'User',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF596174),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFFD4D8E3)),
                  ),
                  InfoLine(
                    icon: Icons.phone_outlined,
                    label: 'PHONE NUMBER',
                    value: profile?.contact ?? '',
                  ),
                  const SizedBox(height: 15),
                  InfoLine(
                    icon: Icons.email_outlined,
                    label: 'EMAIL ADDRESS',
                    value: profile?.email ?? '',
                  ),
                  const SizedBox(height: 15),
                  InfoLine(
                    icon: Icons.location_on_outlined,
                    label: 'ADDRESS',
                    value: profile?.address ?? '',
                  ),
                  const SizedBox(height: 15),
                  InfoLine(
                    icon: Icons.cake_outlined,
                    label: 'BIRTHDAY',
                    value: profile?.birthday ?? '',
                  ),
                  const SizedBox(height: 15),
                  InfoLine(
                    icon: Icons.person_outline,
                    label: 'GENDER',
                    value: profile?.gender ?? '',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 17),
                      label: const Text('Logout'),
                      style: const ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xFFB31321),
                        ),
                        side: WidgetStatePropertyAll(
                          BorderSide(color: Color(0xFFB31321)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 19, color: const Color(0xFF4A5364)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
                color: muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    required this.role,
    required this.onBack,
    required this.onSave,
    super.key,
  });
  final UserRole role;
  final VoidCallback onBack, onSave;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController name = TextEditingController(
    text: widget.role == UserRole.boarder ? 'Alex Eala' : 'Jhes BH',
  );
  late final TextEditingController phone = TextEditingController(
    text: '0912 345 6789',
  );
  late final TextEditingController email = TextEditingController(
    text: widget.role == UserRole.boarder
        ? 'alexeala@gmail.com'
        : 'jhes.bh@gmail.com',
  );
  late final TextEditingController address = TextEditingController(
    text: 'Poblacion Norte, Clarin, Bohol',
  );
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TopBar(
        title: 'Edit Profile',
        onBack: widget.onBack,
        action: const SizedBox.shrink(),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: CardShell(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 47,
                        backgroundImage: NetworkImage(
                          widget.role == UserRole.boarder
                              ? boarderAvatarImage
                              : landownerAvatarImage,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Change Photo',
                          style: TextStyle(fontSize: 15, color: blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const FieldLabel('FULL NAME'),
                TextFieldBox(
                  controller: name,
                  prefixIcon: Icons.person_outline,
                ),
                const FieldLabel('PHONE NUMBER'),
                TextFieldBox(
                  controller: phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const FieldLabel('EMAIL ADDRESS'),
                TextFieldBox(controller: email, prefixIcon: Icons.mail_outline),
                const FieldLabel('ADDRESS'),
                TextFieldBox(
                  controller: address,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
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
                        onPressed: widget.onSave,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class BottomNav extends StatelessWidget {
  const BottomNav({
    required this.index,
    required this.onHome,
    required this.onFavorites,
    required this.onProfile,
    super.key,
  });
  final int index;
  final VoidCallback onHome, onFavorites, onProfile;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: line)),
    ),
    child: NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: paleBlue,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? blue : muted,
            size: 23,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? blue : muted,
          ),
        ),
      ),
      child: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: (value) {
          FocusScope.of(context).unfocus();
          [onHome, onFavorites, onProfile][value]();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.text,
    super.key,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 100),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 45, color: const Color(0xFFB9C4D2)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    ),
  );
}

class Photo extends StatelessWidget {
  const Photo({
    required this.url,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(7)),
    super.key,
  });
  final String? url;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final source = url?.trim() ?? '';
    final Widget fallback = Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFE3EAF2),
      child: const Icon(Icons.image_outlined, color: muted, size: 30),
    );
    Widget content = fallback;
    if (source.isNotEmpty) {
      final uri = Uri.tryParse(source);
      ImageProvider<Object>? provider;
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        provider = NetworkImage(source);
      } else if (source.startsWith('assets/') || source.startsWith('asset:')) {
        provider = AssetImage(source.replaceFirst(RegExp(r'^asset:(//)?'), ''));
      } else if (uri?.scheme == 'data') {
        try {
          final data = uri?.data;
          if (data != null) provider = MemoryImage(data.contentAsBytes());
        } on FormatException {
          provider = null;
        }
      } else {
        provider = localListingImage(source);
      }
      if (provider != null) {
        content = Image(
          image: provider,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => fallback,
        );
      }
    }
    return ClipRRect(borderRadius: borderRadius, child: content);
  }
}
