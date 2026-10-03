import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonStyle { primary, secondary, tonal, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textStyle = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(fontWeight: FontWeight.w600);
    final action = loading ? null : onPressed;
    const size = Size.fromHeight(56);
    const shape = StadiumBorder();

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.muted),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    switch (style) {
      case AppButtonStyle.primary:
        return FilledButton(onPressed: action, child: child);
      case AppButtonStyle.secondary:
        return OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.text,
            minimumSize: size,
            shape: shape,
            side: BorderSide(color: c.text, width: 1.5),
            textStyle: textStyle,
          ),
          child: child,
        );
      case AppButtonStyle.tonal:
        return FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            backgroundColor: c.surfaceAlt,
            foregroundColor: c.text,
          ),
          child: child,
        );
      case AppButtonStyle.text:
        return TextButton(
          onPressed: action,
          style: TextButton.styleFrom(
            foregroundColor: c.text,
            minimumSize: const Size(0, 44),
            textStyle: textStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
          child: child,
        );
    }
  }
}