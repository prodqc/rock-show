import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../config/theme/app_spacing.dart';
import 'widgets/venue_card.dart';

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(nearbyVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Venues', style: Theme.of(context).textTheme.displaySmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/venue/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search venues…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: venuesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (venues) {
                final query = _searchCtrl.text.toLowerCase().trim();
                final filtered = query.isEmpty
                    ? venues
                    : venues
                        .where((v) => v.nameLower.contains(query))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.location_city_rounded,
                    title: query.isEmpty
                        ? 'No venues found'
                        : 'No results for "$query"',
                    subtitle: query.isEmpty ? 'Add a venue to get started' : null,
                    actionLabel: query.isEmpty ? 'Add Venue' : null,
                    onAction: query.isEmpty
                        ? () => context.push('/venue/create')
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final venue = filtered[index];
                    return VenueCard(
                      venue: venue,
                      onTap: () => context.push('/venue/${venue.venueId}'),
                    )
                        .animate(delay: Duration(milliseconds: 40 * index))
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.04, duration: 250.ms,
                            curve: Curves.easeOut);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
