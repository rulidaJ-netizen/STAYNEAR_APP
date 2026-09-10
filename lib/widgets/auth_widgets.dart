part of '../main.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.controller,
    this.icon,
    this.hint = '',
    this.obscure = false,
    this.showText = false,
    this.showLabel = true,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.onChanged,
    this.onToggle,
    super.key,
  });
  final String label, hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscure, showText, showLabel;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onToggle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showLabel) ...[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 5),
      ],
      TextFormField(
        controller: controller,
        obscureText: obscure && !showText,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        maxLength: maxLength,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: ink),
        decoration: InputDecoration(
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 18, color: const Color(0xFF9FA9B8)),
            suffixIcon: suffixIcon ?? (onToggle == null
              ? null
              : IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    showText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF9FA9B8),
                  ),
                )),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA5AFBC)),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          errorMaxLines: 2,
          errorStyle: const TextStyle(
            fontSize: 11,
            height: 1.1,
            color: Colors.red,
          ),
        ),
      ),
    ],
  );
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.showRole = false,
    this.roleLabel = 'Landowner',
    super.key,
  });
  final bool showRole;
  final String roleLabel;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: blue,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(
          Icons.home_work_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 5),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'StayNear',
            style: TextStyle(
              color: blue,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          if (showRole)
            Text(
              roleLabel,
              style: const TextStyle(color: muted, fontSize: 8, height: 1),
            ),
        ],
      ),
    ],
  );
}

class Segmented extends StatelessWidget {
  const Segmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: List.generate(
        labels.length,
        (i) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected == i ? blue : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected == i ? Colors.white : muted,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CardShell extends StatelessWidget {
  const CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
    ),
    child: child,
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}

class TextFieldBox extends StatelessWidget {
  const TextFieldBox({
    this.hint = '',
    this.obscure = false,
    this.maxLines = 1,
    this.controller,
    this.prefixIcon,
    this.fillColor = const Color(0xFFF7F9FC),
    this.borderColor = line,
    this.borderRadius = 5,
    this.prefixIconSize = 18,
    this.prefixIconColor = muted,
    this.hintColor = const Color(0xFFA5AFBC),
    this.prefixIconConstraints,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 9,
    ),
    this.textFontSize = 11,
    this.hintFontSize = 10,
    super.key,
  });
  final String hint;
  final bool obscure;
  final int maxLines;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Color fillColor, borderColor;
  final double borderRadius;
  final double prefixIconSize;
  final Color prefixIconColor, hintColor;
  final BoxConstraints? prefixIconConstraints;
  final EdgeInsetsGeometry contentPadding;
  final double textFontSize, hintFontSize;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    maxLines: maxLines,
    style: TextStyle(fontSize: textFontSize, color: ink),
    decoration: InputDecoration(
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: prefixIconSize, color: prefixIconColor),
      prefixIconConstraints: prefixIconConstraints,
      hintText: hint,
      hintStyle: TextStyle(fontSize: hintFontSize, color: hintColor),
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: blue),
      ),
    ),
  );
}

class TopBar extends StatelessWidget {
  const TopBar({required this.title, this.onBack, this.action, super.key});
  final String title;
  final VoidCallback? onBack;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    child: Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),
          const SizedBox(width: 3),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        action ??
            const Icon(Icons.notifications_none_rounded, size: 21, color: ink),
      ],
    ),
  );
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.onProfile, super.key});
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 11, 16, 9),
    child: Row(
      children: [
        const AppLogo(showRole: true),
        const Spacer(),
        IconButton(
          onPressed: onProfile,
          icon: const Icon(Icons.person_outline_rounded, size: 21, color: ink),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28),
        ),
      ],
    ),
  );
}
