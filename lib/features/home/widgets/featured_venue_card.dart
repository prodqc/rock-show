import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/venue_model.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../../config/theme/app_spacing.dart';

class FeaturedVenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const FeaturedVenueCard({
    required this.venue,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: SizedBox(
        width: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: venue.photos.isNotEmpty
                        ? Hero(
                            tag: 'venue-${venue.venueId}',
                            child: CachedNetworkImage(
                              imageUrl: venue.photos.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                highlightColor: theme.colorScheme.surface
                                    .withValues(alpha: 0.8),
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.location_city,
                                    size: 40,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4)),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.location_city,
                                size: 40,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(venue.address.city,
                            style: theme.textTheme.bodySmall),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
