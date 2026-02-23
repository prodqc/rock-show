import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
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
  int _rating = 0;
  final _textCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final collection = widget.parentType == 'venue'
          ? 'venues'
          : 'shows';
      final docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.parentId)
          .collection('reviews')
          .doc();

      final now = DateTime.now();
      final review = ReviewModel(
        reviewId: docRef.id,
        parentType: widget.parentType,
        parentId: widget.parentId,
        authorUid: user!.uid,
        authorDisplayName: user.displayName ?? 'Anonymous',
        authorAvatarUrl: user.photoURL ?? '',
        rating: _rating,
        text: _textCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(review.toFirestore());
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Rating',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StarRating(
                rating: _rating.toDouble(),
                size: 40,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _textCtrl,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Your review (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
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