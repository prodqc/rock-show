import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/show_model.dart';
import '../../../shared/widgets/genre_chip.dart';
import '../../../config/theme/app_spacing.dart';

class NearbyShowCard extends StatelessWidget {
  final ShowModel show;
  final VoidCallback onTap;

  const NearbyShowCard({required this.show, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(show.date);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flyer hero image
              if (show.flyerUrl.isNotEmpty)
                Hero(
                  tag: 'show-${show.showId}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      show.flyerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.music_note, size: 48),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(show.title,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(show.venueName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        )),
                    const SizedBox(height: 4),
                    Text(dateStr, style: theme.textTheme.bodySmall),
                    if (show.genres.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        children: show.genres
                            .take(3)
                            .map((g) => GenreChip(label: g))
                            .toList(),
                      ),
                    ],
                    if (show.coverCharge != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '\$${show.coverCharge!.toStringAsFixed(0)} · ${show.ageRestriction}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}