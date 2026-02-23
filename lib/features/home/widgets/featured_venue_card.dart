import 'package:flutter/material.dart';
import '../../../models/venue_model.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_radius.dart';

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
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: venue.photos.isNotEmpty
                      ? Hero(
                          tag: 'venue-${venue.venueId}',
                          child: Image.network(venue.photos.first,
                              fit: BoxFit.cover),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.location_city, size: 40),
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
                            StarRating(rating: venue.stats.avgRating, size: 14),
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
    );
  }
}