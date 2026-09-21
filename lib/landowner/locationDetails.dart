part of '../main.dart';

extension _LocationDetailsStep on _RoomWizardState {
  Widget _locationDetails() => Form(
    key: locationForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeading(
          'Location Details',
          'Help students find your property with accurate address and map details.',
        ),
        const SizedBox(height: 32),
        _stepLabel('Full Address', required: true),
        _stepField(
          address,
          'Barangay, Municipality, City',
          keyboard: TextInputType.streetAddress,
          fill: const Color(0xFFF1F5F9),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter the full address.'
              : null,
        ),
        const SizedBox(height: 24),
        _stepLabel('Distance from University'),
        _stepField(
          distance,
          'Enter distance information',
          keyboard: TextInputType.text,
          fill: const Color(0xFFF1F5F9),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter the distance from the university.'
              : null,
        ),
        const SizedBox(height: 24),
        _stepLabel('Reference Map'),
        _stepField(
          referenceMap,
          'Paste a Google Maps link',
          keyboard: TextInputType.url,
          fill: const Color(0xFFF1F5F9),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide the exact property location.';
            }
            if (PropertyLocationService.savedMapUri(value) == null) {
              return 'Please enter a valid Google Maps link.';
            }
            return PropertyLocationService.coordinatesFromMapLink(value) == null
                ? 'Please use a Google Maps link containing exact coordinates.'
                : null;
          },
        ),
        const SizedBox(height: 32),
        const Divider(height: 1, color: Color(0xFFE9F1FE)),
        const SizedBox(height: 24),
        _stepActions(_publishListing, publish: true),
      ],
    ),
  );

  Future<void> _publishListing() async {
    if (publishing || pickingPhoto) return;
    final earlierError =
        _basicValidationMessage() ?? _pricingValidationMessage();
    if (earlierError != null) {
      _showValidationMessage(earlierError);
      return;
    }
    if (!locationForm.currentState!.validate()) return;
    if (photos.every((photo) => photo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one property photo.'),
        ),
      );
      return;
    }
    final rooms = int.tryParse(availableRooms.text.trim()) ?? 0;
    final point = PropertyLocationService.coordinatesFromMapLink(
      referenceMap.text,
    );
    final selectedPhotos = photos.whereType<String>().toList();
    _refresh(() => publishing = true);
    try {
      await widget.onPublish(
        Listing(
          id: _publishId ??= Listing(
            title: '',
            address: '',
            price: 0,
            image: null,
          ).id,
          title: name.text.trim(),
          address: address.text.trim(),
          price:
              int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          image: selectedPhotos.first,
          photos: selectedPhotos,
          availableRooms: rooms,
          totalRooms: int.tryParse(totalRooms.text.trim()) ?? rooms,
          amenities: selectedAmenities.toList(),
          description: description.text.trim(),
          contact: contact.text.trim(),
          available: rooms > 0,
          latitude: point?.latitude,
          longitude: point?.longitude,
          houseInformation: {
            if (distance.text.trim().isNotEmpty)
              'Distance from University': distance.text.trim(),
            if (referenceMap.text.trim().isNotEmpty)
              'Reference Map': referenceMap.text.trim(),
          },
        ),
      );
      if (!mounted) return;
      await _showPublishedDialog();
      if (!mounted) return;
      _clearDraft();
      widget.onPublished?.call();
    } catch (error, stackTrace) {
      debugPrint('PUBLISH LISTING ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(backendMessage(error))));
      }
    } finally {
      if (mounted) _refresh(() => publishing = false);
    }
  }

  Future<void> _showPublishedDialog() async {
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 68),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(28, 32, 28, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(Icons.check_rounded, color: blue, size: 48),
                ),
                SizedBox(height: 24),
                Text(
                  'Listing published successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await dialog;
  }

  void _clearDraft() {
    for (final controller in [
      name,
      description,
      totalRooms,
      price,
      availableRooms,
      address,
      contact,
      distance,
      referenceMap,
    ]) {
      controller.clear();
    }
    photos.fillRange(0, photos.length, null);
    selectedAmenities
      ..clear()
      ..addAll(const ['WiFi', 'Air Conditioning']);
    photoError = null;
    _publishId = null;
  }
}
