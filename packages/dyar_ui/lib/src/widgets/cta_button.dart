import 'package:flutter/material.dart';
import '../tokens.dart';

/// زر CTA رئيسي — ارتفاع 54px (وفق QA spec ≥52px) مع حالة تحميل.
class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final String? trailing; // مثل السعر في "احجز الآن  ₪5.00"

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 22, width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: trailing == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ]),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
    );
  }
}

/// تبديل "نشط/متصل" الكبير (تطبيقا التاجر والسائق).
class ActiveToggle extends StatelessWidget {
  const ActiveToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeLabel,
    required this.inactiveLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String activeLabel, inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = value ? DyarTokens.success : DyarTokens.inkMuted;
    return Material(
      color: value
          ? DyarTokens.success.withValues(alpha: 0.12)
          : Colors.grey.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(DyarTokens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(DyarTokens.radiusLg),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: value, onChanged: onChanged,
                  activeThumbColor: DyarTokens.success),
              const SizedBox(width: 4),
              Text(
                value ? activeLabel : inactiveLabel,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
