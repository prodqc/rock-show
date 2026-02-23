import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../models/activity_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../config/theme/app_spacing.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.people,
          title: 'Sign in to see activity',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity',
            style: Theme.of(context).textTheme.displaySmall),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity')
            .where('recipientUid', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No activity yet',
              subtitle: 'Follow people to see their updates here',
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final activity = ActivityModel.fromFirestore(docs[index]);
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: activity.actorAvatarUrl.isNotEmpty
                      ? NetworkImage(activity.actorAvatarUrl)
                      : null,
                  child: activity.actorAvatarUrl.isEmpty
                      ? Text(activity.actorDisplayName.isNotEmpty
                          ? activity.actorDisplayName[0]
                          : '?')
                      : null,
                ),
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity.actorDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${_actionText(activity.type)} '),
                      TextSpan(
                        text: activity.targetName,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                subtitle: activity.snippet.isNotEmpty
                    ? Text(activity.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                    : null,
                onTap: () {
                  if (activity.targetType == 'venue') {
                    context.push('/venue/${activity.targetId}');
                  } else if (activity.targetType == 'show') {
                    context.push('/show/${activity.targetId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _actionText(String type) {
    switch (type) {
      case 'review_posted':
        return 'reviewed';
      case 'show_created':
        return 'posted a show at';
      case 'venue_created':
        return 'added';
      case 'followed_user':
        return 'followed';
      default:
        return 'interacted with';
    }
  }
}