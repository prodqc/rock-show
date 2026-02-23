import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_radius.dart';

class VenuePreviewSheet extends StatelessWidget {
  final String venueId;
  final String venueName;
  final String venueAddress;
  final VoidCallback onClose;

  const VenuePreviewSheet({
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.sheetBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(venueName,
                    style: theme.textTheme.headlineMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          Text(venueAddress, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/venue/$venueId'),
              child: const Text('View Venue'),
            ),
          ),
        ],
      ),
    );
  }
}