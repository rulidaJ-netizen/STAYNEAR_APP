part of '../main.dart';

extension _PricingAndAvailabilityStep on _RoomWizardState {
  Widget _pricingAndAvailability() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _stepHeading(
        'Pricing & Availability',
        'Set the monthly rent, room inventory, and amenities students can expect from your listing.',
      ),
      const SizedBox(height: 32),
      _stepLabel('Monthly Rent (PHP)', required: true),
      _stepField(price, '', prefix: '₱'),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stepLabel('Total Rooms', required: true),
                _stepField(totalRooms, '0'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stepLabel('Available Rooms', required: true),
                _stepField(availableRooms, '0'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      _stepLabel('Amenities'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in [
            'WiFi',
            'Air Conditioning',
            'Study Desk',
            'Shared Kitchen',
            'Private Bathroom',
            'CCTV',
            'Laundry Area',
            'Parking',
            'Balcony',
          ])
            ChoiceChip(
              label: Text(label),
              selected: selectedAmenities.contains(label),
              onSelected: (selected) => _refresh(() {
                selected
                    ? selectedAmenities.add(label)
                    : selectedAmenities.remove(label);
              }),
              showCheckmark: false,
              selectedColor: blue,
              backgroundColor: paleBlue,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selectedAmenities.contains(label) ? Colors.white : blue,
              ),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
      const SizedBox(height: 24),
      const Divider(height: 1, color: Color(0xFFE9F1FE)),
      const SizedBox(height: 32),
      _stepActions(_pricingNext),
    ],
  );

  void _pricingNext() {
    final message = _pricingValidationMessage();
    if (message != null) {
      _showValidationMessage(message);
      return;
    }
    widget.onNext();
  }
}
