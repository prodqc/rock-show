import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/moderation_providers.dart';
import '../../providers/report_providers.dart';
import '../../providers/user_providers.dart';

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final authUser = ref.watch(currentUserProvider);
    if (authUser == null || !isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access required')),
      );
    }

    final pendingVenues = ref.watch(pendingVenuesProvider);
    final pendingClaims = ref.watch(pendingVenueClaimsProvider);
    final openReports = ref.watch(openReportsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Venues'),
              Tab(text: 'Claims'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            pendingVenues.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (venues) {
                if (venues.isEmpty) {
                  return const Center(child: Text('No pending venues'));
                }
                return ListView.builder(
                  itemCount: venues.length,
                  itemBuilder: (_, i) {
                    final venue = venues[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: ListTile(
                        title: Text(venue.name),
                        subtitle: Text(venue.address.formatted),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(moderationRepositoryProvider)
                                    .rejectVenue(
                                      venueId: venue.venueId,
                                      adminUid: authUser.uid,
                                    );
                              },
                              child: const Text('Reject'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(moderationRepositoryProvider)
                                    .approveVenue(
                                      venueId: venue.venueId,
                                      adminUid: authUser.uid,
                                    );
                              },
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            pendingClaims.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (claims) {
                if (claims.isEmpty) {
                  return const Center(child: Text('No pending claims'));
                }
                return ListView.builder(
                  itemCount: claims.length,
                  itemBuilder: (_, i) {
                    final claim = claims[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venue ${claim.venueId}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                                '${claim.claimantName} (${claim.claimantEmail})'),
                            Text('Role: ${claim.claimantRole}'),
                            const SizedBox(height: AppSpacing.xs),
                            Text(claim.message),
                            if (claim.supportingInfo.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child:
                                    Text('Supporting: ${claim.supportingInfo}'),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(moderationRepositoryProvider)
                                        .rejectVenueClaim(
                                          claimId: claim.id,
                                          adminUid: authUser.uid,
                                        );
                                  },
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ElevatedButton(
                                  onPressed: () async {
                                    await ref
                                        .read(moderationRepositoryProvider)
                                        .approveVenueClaim(
                                          claimId: claim.id,
                                          adminUid: authUser.uid,
                                        );
                                  },
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            openReports.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(child: Text('No open reports'));
                }
                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (_, i) {
                    final report = reports[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: ListTile(
                        title: Text(
                            '${report.entityType} · ${report.reasonCategory}'),
                        subtitle: Text(
                          report.reason.isEmpty
                              ? report.entityId
                              : '${report.entityId}\n${report.reason}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(reportRepositoryProvider)
                                    .updateReportStatus(
                                      reportId: report.id,
                                      status: 'dismissed',
                                      adminUid: authUser.uid,
                                    );
                              },
                              child: const Text('Dismiss'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(reportRepositoryProvider)
                                    .updateReportStatus(
                                      reportId: report.id,
                                      status: 'resolved',
                                      adminUid: authUser.uid,
                                    );
                              },
                              child: const Text('Resolve'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
