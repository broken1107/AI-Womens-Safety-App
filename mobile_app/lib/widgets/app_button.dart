import 'package:flutter/material.dart';

enum AppButtonStyle { filled, tonal, outlined, text }

/// A consistently sized, loading-aware action button.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style = AppButtonStyle.filled,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final content = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.3),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(label),
            ],
          );

    final Widget button;
    switch (style) {
      case AppButtonStyle.filled:
        button = FilledButton(onPressed: callback, child: content);
      case AppButtonStyle.tonal:
        button = FilledButton.tonal(onPressed: callback, child: content);
      case AppButtonStyle.outlined:
        button = OutlinedButton(onPressed: callback, child: content);
      case AppButtonStyle.text:
        button = TextButton(onPressed: callback, child: content);
    }

    return SizedBox(width: expand ? double.infinity : null, child: button);
  }
}
