import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/venue_providers.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/star_rating.dart';
import '../../shared/widgets/genre_chip.dart';
import '../../config/theme/app_spacing.dart';

class VenueDetailScreen extends ConsumerWidget {
  final String venueId;
  const VenueDetailScreen({required this.venueId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final venueAsync = ref.watch(venueDetailProvider(venueId));
    final theme = Theme.of(context);

    return venueAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (venue) {
        if (venue == null) {
          return const Scaffold(body: Center(child: Text('Venue not found')));
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero image
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(venue.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white)),
                  background: venue.photos.isNotEmpty
                      ? Hero(
                          tag: 'venue-${venue.venueId}',
                          child: CachedNetworkImage(
                            imageUrl: venue.photos.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                              color: theme.colorScheme.primary,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : Container(color: theme.colorScheme.primary),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Rating
                    if (venue.stats.ratingCount > 0)
                      Row(
                        children: [
                          StarRating(rating: venue.stats.avgRating),
                          const SizedBox(width: 8),
                          Text(
                            '${venue.stats.avgRating.toStringAsFixed(1)} (${venue.stats.ratingCount} reviews)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    if (venue.isVerified) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Verified Venue',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    if (venue.status == 'Pending') ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'This venue is pending moderation approval.',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Address
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(venue.address.formatted),
                      subtitle: venue.capacity != null
                          ? Text('Capacity: ${venue.capacity}')
                          : null,
                    ),

                    // Tags
                    if (venue.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            venue.tags.map((t) => GenreChip(label: t)).toList(),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/venue/$venueId/review'),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Write Review'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/show/create?venueId=$venueId'),
                            icon: const Icon(Icons.add),
                            label: const Text('Post Show'),
                          ),
                        ),
                      ],
                    ),
                    if (venue.claimedBy == null) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: authUser == null
                              ? null
                              : () => context.push(
                                  '/venue/$venueId/claim?name=${Uri.encodeComponent(venue.name)}'),
                          icon: const Icon(Icons.business_center_outlined),
                          label: const Text('Claim This Venue'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: authUser == null
                            ? null
                            : () => context.push('/report/venue/$venueId'),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report data'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Upcoming shows section (stub)
                    SectionHeader(
                      title: 'Upcoming Shows',
                      actionLabel: 'See all',
                      onAction: () {},
                    ),
                    const Center(
                        child: Text('Shows at this venue will appear here')),

                    const SizedBox(height: AppSpacing.lg),

                    // Reviews section (stub)
                    SectionHeader(
                      title: 'Reviews',
                      actionLabel: 'See all',
                      onAction: () {},
                    ),
                    const Center(child: Text('Reviews will appear here')),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
