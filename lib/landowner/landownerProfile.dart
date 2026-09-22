part of '../main.dart';

class LandownerProfilePage extends StatelessWidget {
  const LandownerProfilePage({
    required this.user,
    required this.onEdit,
    required this.onLogout,
    required this.onHome,
    required this.onFavorites,
    super.key,
  });
  final UserProfile? user;
  final VoidCallback onEdit, onLogout, onHome, onFavorites;

  Widget _buildLandownerProfile() {
    const textStyle = TextStyle(color: ink, fontWeight: FontWeight.w400);
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: blue,
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
                      child: LandownerProfileAvatar(
                        source: user?.profilePhoto,
                        size: 92,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.fullName ?? 'Profile',
                      textAlign: TextAlign.center,
                      style: textStyle.copyWith(
                        fontSize: 24,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
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
                          fontSize: 12,
                          height: 1.5,
                          color: muted,
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
                    _landownerDetail(
                      Icons.phone,
                      'PHONE NUMBER',
                      user?.contact ?? '',
                    ),
                    const SizedBox(height: 17),
                    _landownerDetail(
                      Icons.mail_outline,
                      'EMAIL ADDRESS',
                      user?.email ?? '',
                    ),
                    const SizedBox(height: 17),
                    _landownerDetail(
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
                            fontSize: 13,
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
                            fontSize: 13,
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

  Widget _landownerDetail(
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
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
                color: muted,
              ),
            ),
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minValueHeight),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: ink,
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
  Widget build(BuildContext context) => _buildLandownerProfile();
}
