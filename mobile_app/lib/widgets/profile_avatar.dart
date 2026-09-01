import 'package:flutter/material.dart';

/// Network-aware profile avatar that falls back to initials without an asset.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 34,
    this.backgroundColor,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;

  static String initialsFor(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'SG';
    return words.map((word) => word.substring(0, 1)).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final source = imageUrl?.trim();
    final hasImage = source != null && source.isNotEmpty;
    final fallback = Center(
      child: Text(
        initialsFor(name),
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: radius * .54,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: '$name profile picture',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? colorScheme.primaryContainer,
        child: ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: hasImage
                ? Image.network(
                    source,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
        ),
      ),
    );
  }
}
