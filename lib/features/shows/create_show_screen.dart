import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import '../../providers/venue_providers.dart';
import '../../models/show_model.dart';
import '../../config/theme/app_spacing.dart';

class CreateShowScreen extends ConsumerStatefulWidget {
  final String? venueId;
  const CreateShowScreen({this.venueId, super.key});

  @override
  ConsumerState<CreateShowScreen> createState() => _CreateShowScreenState();
}

class _CreateShowScreenState extends ConsumerState<CreateShowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();
  final _promoterCtrl = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final TimeOfDay _doorsTime = const TimeOfDay(hour: 19, minute: 0);
  String _ageRestriction = 'all-ages';
  final List<String> _genres = [];
  final List<TextEditingController> _lineupCtrls = [TextEditingController()];
  bool _loading = false;

  String? _selectedVenueId;
  final String _selectedVenueName = '';

  @override
  void initState() {
    super.initState();
    _selectedVenueId = widget.venueId;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVenueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a venue')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final venue =
          await ref.read(venueRepositoryProvider).getVenue(_selectedVenueId!);
      final now = DateTime.now();
      final showDate = DateTime(_date.year, _date.month, _date.day,
          _doorsTime.hour, _doorsTime.minute);

      final doc = FirebaseFirestore.instance.collection('shows').doc();
      final show = ShowModel(
        showId: doc.id,
        venueId: _selectedVenueId!,
        venueName: venue?.name ?? _selectedVenueName,
        venueLocation: VenueGeo(
          lat: venue?.location.lat ?? 0,
          lng: venue?.location.lng ?? 0,
          geohash: venue?.location.geohash ?? '',
        ),
        title: _titleCtrl.text.trim(),
        date: showDate,
        doorsTime: showDate,
        lineup: _lineupCtrls
            .asMap()
            .entries
            .where((e) => e.value.text.trim().isNotEmpty)
            .map((e) =>
                LineupAct(name: e.value.text.trim(), order: e.key))
            .toList(),
        genres: _genres,
        coverCharge: double.tryParse(_coverCtrl.text),
        ageRestriction: _ageRestriction,
        ticketUrl: _ticketCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        promoter: _promoterCtrl.text.trim(),
        createdBy: user!.uid,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set(show.toFirestore());
      if (mounted) context.go('/show/${doc.id}');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Show')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Show Title *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Venue selector (simplified — shows search or pre-selected)
              if (_selectedVenueId != null)
                Card(
                  child: ListTile(
                    title: Text(_selectedVenueName.isNotEmpty
                        ? _selectedVenueName
                        : 'Venue selected'),
                    trailing: TextButton(
                      onPressed: () =>
                          setState(() => _selectedVenueId = null),
                      child: const Text('Change'),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Show venue search bottom sheet
                  },
                  icon: const Icon(Icons.location_city),
                  label: const Text('Select Venue *'),
                ),
              const SizedBox(height: AppSpacing.md),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEE, MMM d, y').format(_date)),
                trailing: TextButton(
                    onPressed: _pickDate, child: const Text('Change')),
              ),

              // Lineup
              Text('Lineup', style: theme.textTheme.titleSmall),
              ..._lineupCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: e.value,
                            decoration: InputDecoration(
                                labelText: 'Act ${e.key + 1}'),
                          ),
                        ),
                        if (e.key > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(
                                () => _lineupCtrls.removeAt(e.key)),
                          ),
                      ],
                    ),
                  )),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _lineupCtrls.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add act'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Cover charge
              TextFormField(
                controller: _coverCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Cover charge (\$)'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Age restriction
              DropdownButtonFormField<String>(
                initialValue: _ageRestriction,
                decoration:
                    const InputDecoration(labelText: 'Age restriction'),
                items: ['all-ages', '18+', '21+']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _ageRestriction = v!),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _ticketCtrl,
                decoration:
                    const InputDecoration(labelText: 'Ticket URL'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.xl),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Post Show'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}