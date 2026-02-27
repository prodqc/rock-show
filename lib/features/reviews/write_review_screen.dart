import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/show_providers.dart';
import '../../providers/venue_providers.dart';
import '../../models/review_model.dart';
import '../../shared/widgets/star_rating.dart';
import '../../config/theme/app_spacing.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String parentType; // 'venue' or 'show'
  final String parentId;

  const WriteReviewScreen({
    required this.parentType,
    required this.parentId,
    super.key,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  double _rating = 0;
  final _textCtrl = TextEditingController();
  bool _loading = false;
  DateTime? _createdAt;

  String get _parentCollection =>
      widget.parentType == 'venue' ? 'venues' : 'shows';

  DocumentReference<Map<String, dynamic>> _reviewRef(String uid) {
    return FirebaseFirestore.instance
        .collection(_parentCollection)
        .doc(widget.parentId)
        .collection('reviews')
        .doc(uid);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadExistingReview);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final snap = await _reviewRef(user.uid).get();
      if (!mounted || !snap.exists) return;
      final existing = ReviewModel.fromFirestore(snap);
      setState(() {
        _rating = existing.rating;
        _textCtrl.text = existing.text;
        _createdAt = existing.createdAt;
      });
    } catch (_) {
      // Leave form empty if existing review cannot be loaded.
    }
  }

  Future<void> _saveReview({
    required bool closeOnSuccess,
    bool silent = false,
  }) async {
    if (_rating <= 0) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating')),
        );
      }
      return;
    }
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw StateError('Sign in is required to write a review.');
      }
      final reviewDocId = user.uid;
      final docRef = _reviewRef(reviewDocId);

      final now = DateTime.now();
      final review = ReviewModel(
        reviewId: reviewDocId,
        parentType: widget.parentType,
        parentId: widget.parentId,
        authorUid: user.uid,
        authorDisplayName: user.displayName ?? 'Anonymous',
        authorAvatarUrl: user.photoURL ?? '',
        rating: _rating,
        text: _textCtrl.text.trim(),
        createdAt: _createdAt ?? now,
        updatedAt: now,
      );

      await docRef.set(review.toFirestore(), SetOptions(merge: true));
      _createdAt ??= now;
      if (widget.parentType == 'venue') {
        ref.invalidate(venueDetailProvider(widget.parentId));
        ref.invalidate(nearbyVenuesProvider);
      } else {
        ref.invalidate(showDetailProvider(widget.parentId));
        ref.invalidate(nearbyShowsProvider);
      }

      if (closeOnSuccess && mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAfterGesture() async {
    await _saveReview(closeOnSuccess: false, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Rating:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StarRating(
                rating: _rating,
                size: 40,
                activeColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _rating = v),
                onChangeEnd: _saveAfterGesture,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _textCtrl,
              maxLines: 6,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Review: (Optional)',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed:
                  _loading ? null : () => _saveReview(closeOnSuccess: true),
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
