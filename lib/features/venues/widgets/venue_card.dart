import 'package:flutter/material.dart';
import '../../../models/venue_model.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../../shared/widgets/genre_chip.dart';
import '../../../config/theme/app_spacing.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const VenueCard({required this.venue, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 100,
                height: 100,
                child: venue.photos.isNotEmpty
                    ? Image.network(venue.photos.first, fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.location_city),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(venue.address.formatted,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      if (venue.stats.ratingCount > 0)
                        Row(
                          children: [
                            StarRating(
                                rating: venue.stats.avgRating, size: 14),
                            const SizedBox(width: 4),
                            Text('(${venue.stats.ratingCount})',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      if (venue.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: venue.tags
                              .take(3)
                              .map((t) => GenreChip(label: t))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}