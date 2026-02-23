import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/show_providers.dart';
import '../../shared/widgets/genre_chip.dart';
import '../../config/theme/app_spacing.dart';

class ShowDetailScreen extends ConsumerWidget {
  final String showId;
  const ShowDetailScreen({required this.showId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(showDetailProvider(showId));
    final theme = Theme.of(context);

    return showAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (show) {
        if (show == null) {
          return const Scaffold(body: Center(child: Text('Show not found')));
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: show.flyerUrl.isNotEmpty
                      ? Hero(
                          tag: 'show-${show.showId}',
                          child: Image.network(show.flyerUrl,
                              fit: BoxFit.cover),
                        )
                      : Container(color: theme.colorScheme.primary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(show.title,
                        style: theme.textTheme.displayMedium),
                    const SizedBox(height: AppSpacing.sm),

                    // Venue link
                    GestureDetector(
                      onTap: () =>
                          context.push('/venue/${show.venueId}'),
                      child: Text(show.venueName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          )),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Date & time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('EEEE, MMMM d, y')
                          .format(show.date)),
                      subtitle: show.doorsTime != null
                          ? Text(
                              'Doors ${DateFormat.jm().format(show.doorsTime!)}${show.startTime != null
                                      ? ' · Show ${DateFormat.jm().format(show.startTime!)}'
                                      : ''}')
                          : null,
                    ),

                    // Cover & age
                    if (show.coverCharge != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attach_money),
                        title: Text(
                            '\$${show.coverCharge!.toStringAsFixed(0)} · ${show.ageRestriction}'),
                      ),

                    // Genres
                    if (show.genres.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        children: show.genres
                            .map((g) => GenreChip(label: g))
                            .toList(),
                      ),
                    ],

                    // Lineup
                    if (show.lineup.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Lineup',
                          style: theme.textTheme.displaySmall),
                      const SizedBox(height: AppSpacing.sm),
                      ...show.lineup.map((act) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${act.order + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(act.name,
                                    style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          )),
                    ],

                    // Description
                    if (show.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(show.description,
                          style: theme.textTheme.bodyMedium),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Ticket button
                    if (show.ticketUrl.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse(show.ticketUrl)),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Get Tickets'),
                      ),

                    if (show.status == 'cancelled')
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cancel,
                                color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text('This show has been cancelled',
                                style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 80),
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