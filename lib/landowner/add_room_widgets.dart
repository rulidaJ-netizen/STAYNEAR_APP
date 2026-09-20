part of '../main.dart';

extension _RoomStepWidgets on _RoomWizardState {
  Widget _laterSteps() => ColoredBox(
    color: canvas,
    child: Column(
      children: [
        _roomHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: widget.step == 1 ? 17 : 33),
                Text(
                  'Step ${widget.step + 1} of 4',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                SizedBox(height: widget.step == 1 ? 6 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.step == 1 ? 45 : 16,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: widget.step == 1 ? 8 : 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i <= widget.step ? blue : line,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      widget.step == 1 ? 16 : 24,
                    ),
                    border: widget.step == 1
                        ? null
                        : Border.all(color: const Color(0xFFE1EBFF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: switch (widget.step) {
                    1 => _uploadPhotos(),
                    2 => _pricingAndAvailability(),
                    _ => _locationDetails(),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stepHeading(String title, String subtitle, {double size = 23}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: size,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, height: 1.6, color: muted),
          ),
        ],
      );

  Widget _stepLabel(String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFBA1A1A)),
            ),
        ],
      ),
      style: const TextStyle(fontSize: 13, height: 1.5, color: ink),
    ),
  );

  Widget _stepField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.number,
    String? prefix,
    String? Function(String?)? validator,
    Color fill = const Color(0xFFEFF4FF),
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    validator: validator,
    style: const TextStyle(fontSize: 12, color: ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: muted),
      prefixIcon: prefix == null
          ? null
          : Center(
              widthFactor: 1,
              child: Text(
                prefix,
                style: const TextStyle(fontSize: 12, color: ink),
              ),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorMaxLines: 3,
    ),
  );

  Widget _stepActions(
    VoidCallback next, {
    bool photos = false,
    bool publish = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final previous = FilledButton(
        onPressed: widget.onPrevious,
        style: _stepButtonStyle(paleBlue, ink),
        child: const Text('Previous'),
      );
      final forward = FilledButton(
        onPressed: pickingPhoto || (publish && publishing) ? null : next,
        style: _stepButtonStyle(blue, Colors.white),
        child: publish && publishing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                publish ? 'Publish Listing' : 'Next',
                textAlign: TextAlign.center,
              ),
      );
      if (MediaQuery.textScalerOf(context).scale(16) > 24) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [previous, const SizedBox(height: 12), forward],
        );
      }
      return Row(
        children: [
          Expanded(child: previous),
          SizedBox(width: photos ? 16 : 24),
          Expanded(child: forward),
        ],
      );
    },
  );

  ButtonStyle _stepButtonStyle(Color background, Color foreground) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
