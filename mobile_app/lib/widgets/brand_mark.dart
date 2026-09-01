import 'package:flutter/material.dart';

/// Text-and-icon brand mark which does not depend on bundled image assets.
class SafetyBrandMark extends StatelessWidget {
  const SafetyBrandMark({super.key, this.compact = false, this.color});

  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brand = color ?? colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 46,
          height: compact ? 36 : 46,
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(compact ? 12 : 15),
          ),
          child: Icon(
            Icons.shield_rounded,
            color: colorScheme.onPrimary,
            size: compact ? 22 : 28,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(
            'Safety Guardian',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
        ],
      ],
    );
  }
}
