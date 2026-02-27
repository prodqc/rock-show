import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_providers.dart';
import '../../providers/saved_shows_provider.dart';
import '../../providers/show_providers.dart';
import '../../shared/widgets/genre_chip.dart';
import '../../config/theme/app_spacing.dart';

class ShowDetailScreen extends ConsumerStatefulWidget {
  final String showId;
  const ShowDetailScreen({required this.showId, super.key});

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  Color? _accentColor;
  bool _colorExtracted = false;

  Future<void> _extractColor(String flyerUrl) async {
    if (_colorExtracted || flyerUrl.isEmpty) return;
    _colorExtracted = true;
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(flyerUrl),
        maximumColorCount: 8,
      );
      if (mounted) {
        setState(() => _accentColor = gen.dominantColor?.color);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final showAsync = ref.watch(showDetailProvider(widget.showId));
    final theme = Theme.of(context);

    return showAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (show) {
        if (show == null) {
          return const Scaffold(body: Center(child: Text('Show not found')));
        }

        // Extract palette once when show loads
        Future.microtask(() => _extractColor(show.flyerUrl));

        final appBarBg = _accentColor ?? theme.colorScheme.surface;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: appBarBg,
                foregroundColor: _accentColor != null
                    ? _accentColor!.computeLuminance() > 0.4
                        ? Colors.black
                        : Colors.white
                    : theme.colorScheme.onSurface,
                actions: [
                  // Save/unsave heart
                  Consumer(builder: (_, consumerRef, __) {
                    final savedIds =
                        consumerRef.watch(savedShowIdsProvider).value ?? {};
                    final isSaved = savedIds.contains(show.showId);
                    return IconButton(
                      icon: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border),
                      color: isSaved ? Colors.red[300] : null,
                      onPressed: authUser == null
                          ? null
                          : () => toggleSaveShow(
                              uid: authUser.uid, showId: show.showId),
                    );
                  }),
                  // Share
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      final dateStr =
                          DateFormat('EEE, MMM d').format(show.date);
                      Share.share(
                        '${show.title} @ ${show.venueName} · $dateStr'
                        '${show.ticketUrl.isNotEmpty ? '\n${show.ticketUrl}' : ''}',
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      show.flyerUrl.isNotEmpty
                          ? Hero(
                              tag: 'show-${show.showId}',
                              child: CachedNetworkImage(
                                imageUrl: show.flyerUrl,
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
                      // Gradient overlay — fades image into accentColor at bottom
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.4, 1.0],
                              colors: [
                                Colors.transparent,
                                (appBarBg).withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(show.title, style: theme.textTheme.displayMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            show.trustLevel == 'verified_owner'
                                ? 'Confirmed by Venue'
                                : 'Community Reported',
                          ),
                        ),
                        if (show.status == 'cancelled')
                          const Chip(label: Text('Cancelled')),
                        if (show.status == 'postponed')
                          const Chip(label: Text('Postponed')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Venue link
                    GestureDetector(
                      onTap: () => context.push('/venue/${show.venueId}'),
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
                      title: Text(
                          DateFormat('EEEE, MMMM d, y').format(show.date)),
                      subtitle: show.doorsTime != null
                          ? Text(
                              'Doors ${DateFormat.jm().format(show.doorsTime!)}${show.startTime != null ? ' · Show ${DateFormat.jm().format(show.startTime!)}' : ''}')
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
                      Text('Lineup', style: theme.textTheme.displaySmall),
                      const SizedBox(height: AppSpacing.sm),
                      ...show.lineup.map((act) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                                        color: Colors.white, fontSize: 12),
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
                      Text(show.description, style: theme.textTheme.bodyMedium),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Ticket button
                    if (show.ticketUrl.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(show.ticketUrl)),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Get Tickets'),
                      ),

                    // Corroborate button
                    if ((show.status == 'community_reported' ||
                            show.trustLevel == 'community') &&
                        authUser != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final showRef = FirebaseFirestore.instance
                                .collection('shows')
                                .doc(show.showId);
                            await FirebaseFirestore.instance
                                .runTransaction((tx) async {
                              final snap = await tx.get(showRef);
                              if (!snap.exists) return;
                              final data = snap.data()!;
                              final currentCount = (data['corroborationCount']
                                              as num? ??
                                          data['corroboration_count'] as num?)
                                      ?.toInt() ??
                                  0;
                              final nextCount = currentCount + 1;
                              final updates = <String, dynamic>{
                                'corroborationCount': nextCount,
                                'updatedAt': FieldValue.serverTimestamp(),
                              };
                              final status =
                                  (data['status'] ?? '').toString();
                              if ((status == 'community_reported' ||
                                      status == 'active') &&
                                  nextCount >= 3) {
                                updates['status'] = 'confirmed';
                              }
                              tx.update(showRef, updates);
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Thanks for corroborating this show.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label:
                            Text('Corroborate (${show.corroborationCount})'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: authUser == null
                            ? null
                            : () => context
                                .push('/report/show/${show.showId}'),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report data'),
                      ),
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
