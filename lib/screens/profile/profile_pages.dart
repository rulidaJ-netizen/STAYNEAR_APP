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

  Widget _buildBoarderProfile() {
    const textStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Color(0xFF191C1E),
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
    return ColoredBox(
      color: const Color(0xFFF7F9FB),
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'Profile',
                    style: textStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004BCC),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: onHome,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 22,
                      color: Color(0xFF434654),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 44),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE6E8EA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x09000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE6E8EA),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x09000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ProfileAvatar(
                        source: user?.profilePhoto,
                        size: 92,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.fullName ?? 'Profile',
                      textAlign: TextAlign.center,
                      style: textStyle.copyWith(
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.roleLabel ?? 'User',
                        style: textStyle.copyWith(
                          fontSize: 16,
                          height: 1.25,
                          color: const Color(0xFF434654),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE0E3E5),
                    ),
                    const SizedBox(height: 24),
                    _boarderDetail(
                      Icons.phone,
                      'PHONE NUMBER',
                      user?.contact ?? '',
                    ),
                    const SizedBox(height: 17),
                    _boarderDetail(
                      Icons.mail_outline,
                      'EMAIL ADDRESS',
                      user?.email ?? '',
                    ),
                    const SizedBox(height: 17),
                    _boarderDetail(
                      Icons.location_on,
                      'ADDRESS',
                      user?.address ?? '',
                      minValueHeight: 48,
                    ),
                    const SizedBox(height: 29),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 22),
                        label: const Text('Edit Profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          textStyle: textStyle.copyWith(
                            fontSize: 18,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0x33000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout, size: 22),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFBA1A1A),
                          side: const BorderSide(
                            color: Color(0xFFBA1A1A),
                            width: 1.5,
                          ),
                          minimumSize: const Size(0, 54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          textStyle: textStyle.copyWith(
                            fontSize: 18,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
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
      ),
    );
  }

  Widget _boarderDetail(
    IconData icon,
    String label,
    String value, {
    double minValueHeight = 24,
  }) => Row(
    children: [
      SizedBox(
        width: 56,
        child: Icon(icon, size: 22, color: const Color(0xFF434654)),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: Color(0xFF434654),
              ),
            ),
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minValueHeight),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: Color(0xFF191C1E),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final profile = user;
    final boarder = profile?.role == UserRole.boarder;
    if (boarder) return _buildBoarderProfile();
    if (profile?.role == UserRole.landlord) {
      return LandownerProfilePage(
        user: profile,
        onEdit: onEdit,
        onLogout: onLogout,
        onHome: onHome,
        onFavorites: onFavorites,
      );
    }
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
                  if (boarder)
                    ProfileAvatar(source: profile?.profilePhoto)
                  else
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFE3EAF2),
                      child: const Icon(Icons.person, size: 42, color: muted),
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
