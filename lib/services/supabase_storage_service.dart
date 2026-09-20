part of '../main.dart';

class SupabaseStorageService {
  SupabaseStorageService({this._client});

  static const bucketName = 'staynear-images';
  static const maxImageSize = 10 * 1024 * 1024;
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? Supabase.instance.client;

  static Future<void> validatePickerFile(XFile file) async {
    final extension = _extension(file.name.isNotEmpty ? file.name : file.path);
    if (!_allowedExtensions.contains(extension)) {
      throw const FormatException(
        'Only JPG, JPEG, PNG, and WEBP images are allowed.',
      );
    }
    final mimeType = file.mimeType?.toLowerCase();
    if (mimeType != null && !_allowedMimeTypes.contains(mimeType)) {
      throw const FormatException(
        'Only JPG, JPEG, PNG, and WEBP images are allowed.',
      );
    }
    final size = await file.length();
    if (size <= 0) throw const FormatException('The selected image is empty.');
    if (size > maxImageSize) {
      throw const FormatException('Image must not exceed 10 MB.');
    }
  }

  Future<String> uploadListingImage(String firebaseUid, String source) =>
      _upload(source, 'listings/$firebaseUid');

  Future<List<String>> uploadListingImages(
    String firebaseUid,
    Iterable<String> sources,
  ) async {
    final uploaded = <String>[];
    try {
      for (final source in sources) {
        uploaded.add(await uploadListingImage(firebaseUid, source));
      }
      return uploaded;
    } catch (_) {
      await deleteImages(uploaded);
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String firebaseUid, String source) =>
      _upload(source, 'profiles/$firebaseUid');

  Future<String> _upload(String source, String folder) async {
    if (_isRemoteUrl(source)) return source;
    final image = await _readAndValidate(source);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final path = '$folder/${timestamp}_${image.name}';
    try {
      final authorization = await _authorizeStorage(
        action: 'create-upload',
        path: path,
        mimeType: image.mimeType,
      );
      final authorizedPath = _requiredString(authorization, 'path');
      final token = _requiredString(authorization, 'token');
      await client.storage
          .from(bucketName)
          .uploadBinaryToSignedUrl(
            authorizedPath,
            token,
            image.bytes,
            FileOptions(contentType: image.mimeType, upsert: false),
          )
          .timeout(const Duration(seconds: 60));
      return client.storage.from(bucketName).getPublicUrl(authorizedPath);
    } on TimeoutException {
      throw StateError(
        'The image upload timed out. Check your connection and try again.',
      );
    } on FunctionException catch (error, stackTrace) {
      debugPrint('SUPABASE STORAGE AUTHORIZATION ERROR: ${error.details}');
      debugPrintStack(stackTrace: stackTrace);
      if (error.status == 401 || error.status == 403) {
        throw StateError('Please log in again before uploading an image.');
      }
      throw StateError('Could not authorize the image upload. Please try again.');
    } on StorageException catch (error, stackTrace) {
      debugPrint('SUPABASE STORAGE UPLOAD ERROR: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      final message = error.message.toLowerCase();
      if (message.contains('row-level security') ||
          message.contains('policy') ||
          message.contains('unauthorized')) {
        throw StateError(
          'Image upload permission was denied. Please contact support.',
        );
      }
      throw StateError('Could not upload the image. Please try again.');
    }
  }

  Future<({Uint8List bytes, String mimeType, String name})> _readAndValidate(
    String source,
  ) async {
    late final Uint8List bytes;
    late final String mimeType;
    late final String extension;
    if (source.startsWith('data:')) {
      final data = UriData.parse(source);
      mimeType = data.mimeType.toLowerCase();
      extension = switch (mimeType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => '',
      };
      bytes = data.contentAsBytes();
    } else {
      final file = XFile(source);
      await validatePickerFile(file);
      extension = _extension(file.name.isNotEmpty ? file.name : source);
      mimeType = _mimeForExtension(extension);
      bytes = await file.readAsBytes();
    }
    if (!_allowedExtensions.contains(extension) ||
        !_allowedMimeTypes.contains(mimeType)) {
      throw const FormatException(
        'Only JPG, JPEG, PNG, and WEBP images are allowed.',
      );
    }
    if (bytes.isEmpty) {
      throw const FormatException('The selected image is empty.');
    }
    if (bytes.length > maxImageSize) {
      throw const FormatException('Image must not exceed 10 MB.');
    }
    return (bytes: bytes, mimeType: mimeType, name: 'image.$extension');
  }

  Future<void> deleteImage(String urlOrPath) async {
    final path = storagePath(urlOrPath);
    if (path == null) return;
    try {
      await _authorizeStorage(action: 'delete', path: path)
          .timeout(const Duration(seconds: 30));
    } catch (error, stackTrace) {
      // Cleanup follows a committed Firestore write and must not roll it back.
      debugPrint('SUPABASE STORAGE DELETE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> deleteImages(Iterable<String> urlsOrPaths) async {
    for (final value in urlsOrPaths) {
      await deleteImage(value);
    }
  }

  Future<Map<String, dynamic>> _authorizeStorage({
    required String action,
    required String path,
    String? mimeType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please log in again.');
    final firebaseToken = await user.getIdToken();
    if (firebaseToken == null || firebaseToken.isEmpty) {
      throw StateError('Please log in again.');
    }
    final response = await client.functions.invoke(
      'storage-authorize',
      headers: {'Authorization': 'Bearer $firebaseToken'},
      body: {
        'action': action,
        'path': path,
        'mimeType': ?mimeType,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw StateError('The storage authorization response was invalid.');
    }
    return Map<String, dynamic>.from(data);
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw StateError('The storage authorization response was invalid.');
    }
    return value;
  }

  String? storagePath(String urlOrPath) {
    if (!urlOrPath.contains('://')) {
      return urlOrPath.startsWith('/') ? urlOrPath.substring(1) : urlOrPath;
    }
    final uri = Uri.tryParse(urlOrPath);
    if (uri == null || uri.host != 'drlaskltdvphtkjualvx.supabase.co') {
      return null;
    }
    final marker = '/storage/v1/object/public/$bucketName/';
    final index = uri.path.indexOf(marker);
    return index < 0
        ? null
        : Uri.decodeComponent(uri.path.substring(index + marker.length));
  }

  static bool _isRemoteUrl(String source) {
    final uri = Uri.tryParse(source);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  static String _extension(String source) {
    final clean = source.split('?').first.split('#').first;
    final name = clean.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static String _mimeForExtension(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => '',
  };
}
