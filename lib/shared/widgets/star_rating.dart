import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int maxStars;
  final ValueChanged<int>? onChanged;

  const StarRating({
    required this.rating,
    this.size = 20,
    this.maxStars = 5,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of $maxStars stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxStars, (i) {
          final starValue = i + 1;
          IconData icon;
          if (rating >= starValue) {
            icon = Icons.star_rounded;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_border_rounded;
          }
          return GestureDetector(
            onTap: onChanged != null ? () => onChanged!(starValue) : null,
            child: Icon(icon, size: size, color: AppColors.starYellow),
          );
        }),
      ),
    );
  }
}