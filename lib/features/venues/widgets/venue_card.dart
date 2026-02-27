import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: venue.photos.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: venue.photos.first,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor:
                                theme.colorScheme.surfaceContainerHighest,
                            highlightColor:
                                theme.colorScheme.surface.withValues(alpha: 0.8),
                            child: Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.location_city),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.location_city),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
