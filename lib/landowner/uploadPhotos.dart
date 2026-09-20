part of '../main.dart';

/// Uses the existing picker boundary, retaining property-sized image data.
class ListingPhotoPicker extends ProfilePhotoPicker {
  @override
  Future<String?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _encode(file);
  }

  @override
  Future<String> _encode(XFile file) async {
    await SupabaseStorageService.validatePickerFile(file);
    final codec = await ui.instantiateImageCodec(
      await file.readAsBytes(),
      targetWidth: 1600,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final bytes = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (bytes == null) {
          throw const FormatException('Could not read the photo.');
        }
        return 'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}';
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

extension _UploadPhotosStep on _RoomWizardState {
  Future<void> _recoverListingPhoto() async {
    try {
      final photo = await photoPicker.recover();
      if (!mounted || photo == null) return;
      final slot = photos.indexOf(null);
      if (slot >= 0) _refresh(() => photos[slot] = photo);
    } catch (_) {
      if (mounted) {
        _refresh(
          () => photoError =
              'Could not recover the selected photo. Please choose it again.',
        );
      }
    }
  }

  Future<void> _choosePhoto(int slot) async {
    if (pickingPhoto || photos[slot] != null) return;
    _refresh(() {
      pickingPhoto = true;
      photoError = null;
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
              if (photoPicker.supportsCamera)
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
      final photo = await photoPicker.pick(source);
      if (mounted && photo != null) _refresh(() => photos[slot] = photo);
    } on FormatException catch (error) {
      if (mounted) _refresh(() => photoError = error.message);
    } on PlatformException {
      if (mounted) {
        _refresh(
          () => photoError = 'Could not access your photos. Check photo permissions and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _refresh(
          () => photoError =
              'Could not read this photo. Please choose another image.',
        );
      }
    } finally {
      if (mounted) _refresh(() => pickingPhoto = false);
    }
  }

  void _photosNext() {
    if (photos.every((photo) => photo == null)) {
      _refresh(() => photoError = 'Please select at least one property photo.');
      return;
    }
    widget.onNext();
  }

  Widget _uploadPhotos() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _stepHeading(
        'Upload Photos',
        'Add high-quality photos to attract more students',
        size: 24,
      ),
      const SizedBox(height: 28),
      const Text(
        'Property Photos *',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: (constraints.maxWidth - 16) / 2,
                height: (constraints.maxWidth - 16) / 2,
                child: _photoSlot(i),
              ),
          ],
        ),
      ),
      const SizedBox(height: 36),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const Text(
            'Upload at least 1 high-quality photo of the room',
            style: TextStyle(fontSize: 13, height: 1.4, color: muted),
          ),
          Text(
            'Selected: ${photos.whereType<String>().length} / 4',
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
      if (photoError != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            photoError!,
            style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13),
          ),
        ),
      const SizedBox(height: 40),
      _stepActions(_photosNext, photos: true),
      const SizedBox(height: 40),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          border: Border.all(color: const Color(0xFFD8E6FF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 19, color: blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo Requirements',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                'Horizontal orientation preferred\nMinimum resolution: 1024×768\nWell-lit, natural lighting\nNo text or watermarks',
                style: TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _photoSlot(int slot) {
    final photo = photos[slot];
    if (photo != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC2C6D6), width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Photo(
              url: photo,
              height: double.infinity,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Remove Photo ${slot + 1}',
              onPressed: pickingPhoto
                  ? null
                  : () => _refresh(() => photos[slot] = null),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x9950555D),
                foregroundColor: Colors.white,
                minimumSize: const Size(32, 32),
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
          onTap: pickingPhoto ? null : () => _choosePhoto(slot),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_upload_outlined, size: 28, color: muted),
              const SizedBox(height: 8),
              Text(
                'Photo ${slot + 1}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSlotBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC2C6D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(12),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 10) {
        canvas.drawPath(
          metric.extractPath(offset, (offset + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
