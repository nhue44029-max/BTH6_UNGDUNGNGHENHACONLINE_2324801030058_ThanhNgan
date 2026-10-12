import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.url,
    this.size = 58,
    this.radius = 16,
  });
  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Container(
      width: size,
      height: size,
      color: AppColors.lightBlue,
      child: url.isEmpty
          ? const Icon(Icons.music_note_rounded, color: AppColors.primary)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
              ),
            ),
    ),
  );
}
