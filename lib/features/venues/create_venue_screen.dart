import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/location_providers.dart';
import '../../models/venue_model.dart';
import '../../models/app_lat_lng.dart';
import '../../services/geohash_service.dart';
import '../../config/theme/app_spacing.dart';

class CreateVenueScreen extends ConsumerStatefulWidget {
  const CreateVenueScreen({super.key});

  @override
  ConsumerState<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends ConsumerState<CreateVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  bool _loading = false;
  final List<String> _selectedTags = [];
  final _availableTags = [
    'Bar', 'Club', 'DIY', 'Outdoor', 'All Ages', 'Theater',
    'House Show', 'Record Store', 'Coffee Shop', '18+', '21+'
  ];
  List<VenueModel> _possibleDuplicates = [];

  Future<void> _checkDuplicates(double lat, double lng) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (lat == 0 && lng == 0) return;

    final dupes = await ref.read(venueRepositoryProvider).checkDuplicates(
      _nameCtrl.text.trim(),
      AppLatLng(latitude: lat, longitude: lng),
    );
    setState(() => _possibleDuplicates = dupes);
    if (dupes.isNotEmpty && mounted) {
      _showDuplicateWarning(lat, lng);
    }
  }

  void _showDuplicateWarning(double lat, double lng) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Possible Duplicate',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            ...(_possibleDuplicates.map((v) => ListTile(
                  title: Text(v.name),
                  subtitle: Text(v.address.formatted),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/venue/${v.venueId}');
                    },
                    child: const Text('View'),
                  ),
                ))),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _submitVenue(lat, lng);
                },
                child: const Text('Create Anyway'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Use current GPS location as the venue's coordinates
    final location = ref.read(effectiveLocationProvider);
    final lat = location?.latitude ?? 0;
    final lng = location?.longitude ?? 0;

    if (lat == 0 && lng == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location unavailable. Enable GPS so we can place the venue on the map.')),
        );
      }
      return;
    }

    await _checkDuplicates(lat, lng);
    if (_possibleDuplicates.isEmpty) {
      await _submitVenue(lat, lng);
    }
  }

  Future<void> _submitVenue(double lat, double lng) async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final geohash = GeohashService().encode(lat, lng);
      final now = DateTime.now();

      final venue = VenueModel(
        venueId: '',
        name: _nameCtrl.text.trim(),
        nameLower: _nameCtrl.text.trim().toLowerCase(),
        address: VenueAddress(
          street: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          zip: _zipCtrl.text.trim(),
          formatted:
              '${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} ${_zipCtrl.text.trim()}',
        ),
        location: VenueLocation(lat: lat, lng: lng, geohash: geohash),
        tags: _selectedTags,
        capacity: int.tryParse(_capacityCtrl.text),
        contact: {
          'website': _websiteCtrl.text.trim(),
          'instagram': _instagramCtrl.text.trim(),
        },
        createdBy: user!.uid,
        createdAt: now,
        updatedAt: now,
      );

      final id = await ref.read(venueRepositoryProvider).createVenue(venue);
      if (mounted) context.go('/venue/$id');
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
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/explore'),
        ),
        title: const Text('Add Venue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Venue Name',
                  hintText: 'e.g. The Mohawk',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. 912 Red River St',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _zipCtrl,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Tags', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags
                    .map((tag) => FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (sel) {
                            setState(() {
                              sel
                                  ? _selectedTags.add(tag)
                                  : _selectedTags.remove(tag);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity (optional)',
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _instagramCtrl,
                decoration: const InputDecoration(
                  labelText: 'Instagram handle',
                  prefixIcon: Icon(Icons.camera_alt),
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The venue will be placed at your current GPS location. '
                'Make sure you are near the venue or location services are on.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_business),
                label: const Text('Create Venue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}