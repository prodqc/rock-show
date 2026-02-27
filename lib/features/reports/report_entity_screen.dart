import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../models/report_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';

class ReportEntityScreen extends ConsumerStatefulWidget {
  final String entityType; // venue | show
  final String entityId;

  const ReportEntityScreen({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  @override
  ConsumerState<ReportEntityScreen> createState() => _ReportEntityScreenState();
}

class _ReportEntityScreenState extends ConsumerState<ReportEntityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsCtrl = TextEditingController();
  bool _loading = false;
  String _category = 'wrong_address';

  static const _categories = [
    ('wrong_address', 'Wrong address'),
    ('venue_closed', 'Venue closed'),
    ('show_cancelled', 'Show cancelled'),
    ('duplicate', 'Duplicate'),
    ('inappropriate_content', 'Inappropriate content'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = ref.read(currentUserProvider);
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sign in is required to submit a report.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final report = ReportModel(
        id: '',
        reporterUserId: authUser.uid,
        entityType: widget.entityType,
        entityId: widget.entityId,
        reasonCategory: _category,
        reason: _detailsCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(reportRepositoryProvider).createReport(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted.')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Inaccurate Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entity: ${widget.entityType} (${widget.entityId})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Reason category'),
                items: _categories
                    .map((c) => DropdownMenuItem<String>(
                          value: c.$1,
                          child: Text(c.$2),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? 'other'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _detailsCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
