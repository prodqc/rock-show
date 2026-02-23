import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/show_providers.dart';
import '../../providers/venue_providers.dart';
import '../../providers/location_providers.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../config/theme/app_spacing.dart';
import 'widgets/nearby_show_card.dart';
import 'widgets/featured_venue_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(effectiveLocationProvider);
    final showsAsync = ref.watch(nearbyShowsProvider);
    final venuesAsync = ref.watch(nearbyVenuesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('GigLocal',
                  style: Theme.of(context).textTheme.displayMedium),
              titlePadding:
                  const EdgeInsets.only(left: AppSpacing.md, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Post a show',
                onPressed: () => context.push('/show/create'),
              ),
            ],
          ),

          // Location status
          if (location == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_off),
                    title: const Text('Location not available'),
                    subtitle: const Text('Enable location or search a city'),
                    trailing: TextButton(
                      onPressed: () {
                        // TODO: Show city search bottom sheet
                      },
                      child: const Text('Search'),
                    ),
                  ),
                ),
              ),
            ),

          // Upcoming shows
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Upcoming Near You',
              actionLabel: 'See all',
              onAction: () {},
            ),
          ),
          showsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error: $e'),
              ),
            ),
            data: (shows) {
              if (shows.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.music_off_rounded,
                    title: 'No upcoming shows nearby',
                    subtitle: 'Be the first to post one!',
                    actionLabel: 'Post a Show',
                    onAction: () => context.push('/show/create'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final show = shows[index];
                    return NearbyShowCard(
                      show: show,
                      onTap: () => context.push('/show/${show.showId}'),
                    );
                  },
                  childCount: shows.length.clamp(0, 10),
                ),
              );
            },
          ),

          // Featured venues
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Venues Near You',
              actionLabel: 'Explore',
              onAction: () => context.go('/explore'),
            ),
          ),
          venuesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Text('Error: $e'),
            ),
            data: (venues) {
              if (venues.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.location_city_rounded,
                    title: 'No venues found nearby',
                    actionLabel: 'Add a Venue',
                    onAction: () => context.push('/venue/create'),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: venues.length.clamp(0, 8),
                    itemBuilder: (context, index) {
                      final venue = venues[index];
                      return FeaturedVenueCard(
                        venue: venue,
                        onTap: () =>
                            context.push('/venue/${venue.venueId}'),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}