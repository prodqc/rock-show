import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/venue_providers.dart';
import '../../providers/auth_providers.dart';
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

  // In production, get from geocoding. Stub for now.
  final double _lat = 0;
  final double _lng = 0;

  bool _loading = false;
  final List<String> _selectedTags = [];
  final _availableTags = [
    'bar', 'club', 'DIY', 'outdoor', 'all-ages', 'theater',
    'house-show', 'record-store', 'coffee-shop'
  ];

  List<VenueModel> _possibleDuplicates = [];

  Future<void> _checkDuplicates() async {
    if (_nameCtrl.text.trim().isEmpty || (_lat == 0 && _lng == 0)) return;
    final dupes = await ref.read(venueRepositoryProvider).checkDuplicates(
          _nameCtrl.text.trim(),
          AppLatLng(latitude: _lat, longitude: _lng),
        );
    setState(() => _possibleDuplicates = dupes);
    if (dupes.isNotEmpty && mounted) {
      _showDuplicateWarning();
    }
  }

  void _showDuplicateWarning() {
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
                  _submitVenue();
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
    // TODO: Geocode the address to get lat/lng
    // For now stub — in production integrate PlaceSearchProvider
    await _checkDuplicates();
    if (_possibleDuplicates.isEmpty) {
      await _submitVenue();
    }
  }

  Future<void> _submitVenue() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      final geohash = GeohashService().encode(_lat, _lng);
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
        location: VenueLocation(lat: _lat, lng: _lng, geohash: geohash),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Venue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Venue Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _streetCtrl,
                decoration: const InputDecoration(labelText: 'Street Address *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _zipCtrl,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tags
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
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity (optional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _instagramCtrl,
                decoration: const InputDecoration(labelText: 'Instagram handle'),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Create Venue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}