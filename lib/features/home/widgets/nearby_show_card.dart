import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/show_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/saved_shows_provider.dart';
import '../../../shared/widgets/genre_chip.dart';
import '../../../config/theme/app_spacing.dart';

class NearbyShowCard extends ConsumerWidget {
  final ShowModel show;
  final VoidCallback onTap;

  const NearbyShowCard({required this.show, required this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(show.date);
    final authUser = ref.watch(currentUserProvider);
    final savedIds = ref.watch(savedShowIdsProvider).value ?? {};
    final isSaved = savedIds.contains(show.showId);

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flyer image — edge-to-edge with save heart overlay
          if (show.flyerUrl.isNotEmpty)
            Stack(
              children: [
                Hero(
                  tag: 'show-${show.showId}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: show.flyerUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: theme.colorScheme.surfaceContainerHighest,
                        highlightColor:
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                        child: Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.music_note, size: 48),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _SaveButton(
                    isSaved: isSaved,
                    onTap: authUser == null
                        ? null
                        : () => toggleSaveShow(
                              uid: authUser.uid,
                              showId: show.showId,
                            ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
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
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback? onTap;

  const _SaveButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? Colors.red[300] : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
