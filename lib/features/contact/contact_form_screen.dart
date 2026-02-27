import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../models/contact_submission_model.dart';
import '../../models/venue_claim_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/moderation_providers.dart';
import '../../providers/user_providers.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final String? venueId;
  final String? venueName;
  final bool isVenueClaim;

  const ContactFormScreen({
    super.key,
    this.venueId,
    this.venueName,
    this.isVenueClaim = false,
  });

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _supportingInfoCtrl = TextEditingController();
  bool _loading = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _roleCtrl.dispose();
    _messageCtrl.dispose();
    _supportingInfoCtrl.dispose();
    super.dispose();
  }

  void _seedFromUser() {
    if (_seeded) return;
    final authUser = ref.read(currentUserProvider);
    final userDoc = ref.read(currentUserDocProvider).value;
    if (authUser != null) {
      _nameCtrl.text = userDoc?.displayName.isNotEmpty == true
          ? userDoc!.displayName
          : (authUser.displayName ?? '');
      _emailCtrl.text = userDoc?.email.isNotEmpty == true
          ? userDoc!.email
          : authUser.email ?? '';
    }
    _subjectCtrl.text = widget.isVenueClaim
        ? 'Claim venue: ${widget.venueName ?? widget.venueId ?? ''}'
        : 'General inquiry';
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(currentUserProvider);
    if (widget.isVenueClaim && authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in is required to claim a venue.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final moderation = ref.read(moderationRepositoryProvider);
      final now = DateTime.now();

      final submission = ContactSubmissionModel(
        id: '',
        userId: authUser?.uid,
        venueId: widget.venueId,
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        submittedAt: now,
      );

      if (widget.isVenueClaim) {
        final claim = VenueClaimModel(
          id: '',
          userId: authUser!.uid,
          venueId: widget.venueId ?? '',
          claimantName: _nameCtrl.text.trim(),
          claimantEmail: _emailCtrl.text.trim(),
          claimantRole: _roleCtrl.text.trim(),
          message: _messageCtrl.text.trim(),
          supportingInfo: _supportingInfoCtrl.text.trim(),
          submittedAt: now,
        );
        await moderation.submitVenueClaim(
          claim: claim,
          contactSubmission: submission,
        );
      } else {
        await moderation.submitContact(submission);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isVenueClaim
              ? 'Claim submitted for admin review.'
              : 'Message sent.'),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFromUser();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVenueClaim ? 'Claim This Venue' : 'Contact Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isVenueClaim && widget.venueName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Venue: ${widget.venueName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Your Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.isVenueClaim) ...[
                TextFormField(
                  controller: _roleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Role at the venue'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              if (widget.isVenueClaim) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _supportingInfoCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Supporting info (optional)',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isVenueClaim ? 'Submit Claim' : 'Send Message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
