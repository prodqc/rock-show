import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import '../../providers/show_providers.dart';
import '../../providers/venue_providers.dart';
import '../../models/show_model.dart';
import '../../config/theme/app_spacing.dart';
import '../../services/image_upload_service.dart';

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
  String _ageRestriction = 'All Ages';
  final List<String> _genres = [];
  final List<TextEditingController> _lineupCtrls = [TextEditingController()];
  bool _loading = false;
  String? _flyerUrl;

  String? _selectedVenueId;
  String _selectedVenueName = '';

  @override
  void initState() {
    super.initState();
    _selectedVenueId = widget.venueId;
    if (_selectedVenueId != null) {
      Future.microtask(() async {
        final venue =
            await ref.read(venueRepositoryProvider).getVenue(_selectedVenueId!);
        if (mounted && venue != null) {
          setState(() => _selectedVenueName = venue.name);
        }
      });
    }
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

  Future<void> _pickFlyer() async {
    final url = await ImageUploadService.pickAndUpload(folder: 'shows');
    if (url != null) {
      setState(() => _flyerUrl = url);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVenueId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a venue')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw StateError('Sign in required');
      final venue =
          await ref.read(venueRepositoryProvider).getVenue(_selectedVenueId!);
      if (venue == null) throw StateError('Venue not found');
      final now = DateTime.now();
      final showDate = DateTime(_date.year, _date.month, _date.day,
          _doorsTime.hour, _doorsTime.minute);
      final ageValue = switch (_ageRestriction) {
        '18+' => '18_plus',
        '21+' => '21_plus',
        _ => 'all_ages',
      };
      final show = ShowModel(
        showId: '',
        venueId: _selectedVenueId!,
        venueName: venue.name,
        venueLocation: VenueGeo(
          lat: venue.location.lat,
          lng: venue.location.lng,
          geohash: venue.location.geohash,
        ),
        title: _titleCtrl.text.trim(),
        date: showDate,
        doorsTime: showDate,
        startTime: showDate,
        lineup: _lineupCtrls
            .asMap()
            .entries
            .where((e) => e.value.text.trim().isNotEmpty)
            .map((e) => LineupAct(name: e.value.text.trim(), order: e.key))
            .toList(),
        genres: _genres,
        genreTags: _genres,
        coverCharge: double.tryParse(_coverCtrl.text),
        priceDoor: double.tryParse(_coverCtrl.text),
        ageRestriction: ageValue,
        ticketUrl: _ticketCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        flyerUrl: _flyerUrl ?? '',
        sourceImageUrl: _flyerUrl ?? '',
        promoter: _promoterCtrl.text.trim(),
        submittedBy: user.uid,
        createdBy: user.uid,
        createdAt: now,
        updatedAt: now,
      );

      final showId =
          await ref.read(showRepositoryProvider).createShowSubmission(
                show: show,
                submitterUid: user.uid,
              );
      if (mounted) {
        ref.invalidate(nearbyShowsProvider);
        context.go('/show/$showId');
      }
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
              // Flyer image picker
              GestureDetector(
                onTap: _loading ? null : _pickFlyer,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _flyerUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _flyerUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                onPressed: () =>
                                    setState(() => _flyerUrl = null),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Add Show Flyer',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                            Text('Tap to upload an image',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

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
                      onPressed: () => setState(() => _selectedVenueId = null),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: e.value,
                            decoration:
                                InputDecoration(labelText: 'Act ${e.key + 1}'),
                          ),
                        ),
                        if (e.key > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                setState(() => _lineupCtrls.removeAt(e.key)),
                          ),
                      ],
                    ),
                  )),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _lineupCtrls.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Add Act'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Cover charge
              TextFormField(
                controller: _coverCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Cover Charge (\$)'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Age restriction
              DropdownButtonFormField<String>(
                initialValue: _ageRestriction,
                decoration: const InputDecoration(labelText: 'Age Restriction'),
                items: ['All Ages', '18+', '21+']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _ageRestriction = v!),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _ticketCtrl,
                decoration: const InputDecoration(labelText: 'Ticket URL'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
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
