part of '../main.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.source, this.size = 84, super.key});
  final String? source;
  final double size;

  ImageProvider<Object>? _provider() {
    final path = source?.trim() ?? '';
    if (path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri?.scheme == 'http' || uri?.scheme == 'https') {
      return NetworkImage(path);
    }
    if (path.startsWith('assets/') || path.startsWith('asset:')) {
      return AssetImage(path.replaceFirst(RegExp(r'^asset:(//)?'), ''));
    }
    if (uri?.scheme == 'data') {
      try {
        final bytes = uri?.data?.contentAsBytes();
        return bytes == null ? null : MemoryImage(bytes);
      } on FormatException {
        return null;
      }
    }
    return localListingImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xFFE3EAF2),
      child: Center(
        child: Icon(Icons.person, size: size * .5, color: muted),
      ),
    );
    final provider = _provider();
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: provider == null
            ? fallback
            : Image(
                image: provider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}
