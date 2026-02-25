import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_providers.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/genre_chip.dart';
import '../../config/theme/app_spacing.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);

    if (authUser == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push('/auth/sign-in'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // If the user doc doesn't exist yet, create it automatically
        if (!snapshot.hasData || !snapshot.data!.exists) {
          _createUserDoc(authUser);
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = UserModel.fromFirestore(snapshot.data!);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile',
                style: theme.textTheme.displaySmall),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/profile/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 36))
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(user.displayName,
                          style: theme.textTheme.displaySmall),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.black, size: 22),
                    ],
                  ],
                ),
                if (user.city.isNotEmpty)
                  Text('${user.city}, ${user.state}',
                      style: theme.textTheme.bodyMedium),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(user.bio,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTile(
                        label: 'Followers',
                        count: user.stats.followerCount),
                    _StatTile(
                        label: 'Following',
                        count: user.stats.followingCount),
                    _StatTile(
                        label: 'Reviews',
                        count: user.stats.reviewsWritten),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user.favoriteGenres.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    children: user.favoriteGenres
                        .map((g) => GenreChip(label: g))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Auto-creates a Firestore user document from the Firebase Auth user.
  static Future<void> _createUserDoc(dynamic authUser) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(authUser.uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'uid': authUser.uid,
        'displayName': authUser.displayName ?? '',
        'username': '',
        'avatarUrl': authUser.photoURL ?? '',
        'bio': '',
        'city': '',
        'state': '',
        'favoriteGenres': <String>[],
        'links': <String, String>{},
        'role': 'user',
        'trustLevel': 1,
        'stats': {
          'followerCount': 0,
          'followingCount': 0,
          'venuesCreated': 0,
          'showsCreated': 0,
          'reviewsWritten': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  const _StatTile({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}