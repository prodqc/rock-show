import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int maxStars;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onChangeEnd;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRating({
    required this.rating,
    this.size = 20,
    this.maxStars = 5,
    this.onChanged,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = activeColor ?? theme.colorScheme.primary;
    final empty = inactiveColor ?? filled.withValues(alpha: 0.28);
    final isInteractive = onChanged != null;
    final totalWidth = size * maxStars;

    void updateFromOffset(double dx) {
      if (onChanged == null) return;
      final clamped = dx.clamp(0.0, totalWidth);
      var value = (clamped / size * 2).ceil() / 2;
      if (value <= 0) value = 0.5;
      if (value > maxStars) value = maxStars.toDouble();
      onChanged!(value);
    }

    Widget stars() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxStars, (i) {
          final starValue = i + 1;
          IconData icon;
          Color color = empty;

          if (rating >= starValue) {
            icon = Icons.star_rounded;
            color = filled;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
            color = filled;
          } else {
            icon = Icons.star_border_rounded;
          }

          return Icon(icon, size: size, color: color);
        }),
      );
    }

    final content = SizedBox(
      width: totalWidth,
      height: size + 8,
      child: Align(
        alignment: Alignment.centerLeft,
        child: stars(),
      ),
    );

    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of $maxStars stars',
      child: isInteractive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  updateFromOffset(details.localPosition.dx),
              onTapUp: (_) => onChangeEnd?.call(),
              onHorizontalDragUpdate: (details) =>
                  updateFromOffset(details.localPosition.dx),
              onHorizontalDragEnd: (_) => onChangeEnd?.call(),
              onHorizontalDragCancel: onChangeEnd,
              child: content,
            )
          : content,
    );
  }
}
