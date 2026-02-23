import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_lat_lng.dart';

class VenueModel {
  final String venueId;
  final String name;
  final String nameLower;
  final VenueAddress address;
  final VenueLocation location;
  final List<String> photos;
  final List<String> tags;
  final int? capacity;
  final Map<String, String> contact;
  final VenueStats stats;
  final String createdBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VenueModel({
    required this.venueId,
    required this.name,
    required this.nameLower,
    required this.address,
    required this.location,
    this.photos = const [],
    this.tags = const [],
    this.capacity,
    this.contact = const {},
    this.stats = const VenueStats(),
    required this.createdBy,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  AppLatLng get appLatLng => AppLatLng(
        latitude: location.lat,
        longitude: location.lng,
      );

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueModel(
      venueId: doc.id,
      name: data['name'] ?? '',
      nameLower: data['nameLower'] ?? '',
      address: VenueAddress.fromMap(data['address'] ?? {}),
      location: VenueLocation.fromMap(data['location'] ?? {}),
      photos: List<String>.from(data['photos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      capacity: data['capacity'],
      contact: Map<String, String>.from(data['contact'] ?? {}),
      stats: VenueStats.fromMap(data['stats'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'nameLower': name.toLowerCase(),
        'address': address.toMap(),
        'location': location.toMap(),
        'photos': photos,
        'tags': tags,
        'capacity': capacity,
        'contact': contact,
        'stats': stats.toMap(),
        'createdBy': createdBy,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

class VenueAddress {
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String formatted;

  const VenueAddress({
    this.street = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.country = 'US',
    this.formatted = '',
  });

  factory VenueAddress.fromMap(Map<String, dynamic> m) => VenueAddress(
        street: m['street'] ?? '',
        city: m['city'] ?? '',
        state: m['state'] ?? '',
        zip: m['zip'] ?? '',
        country: m['country'] ?? 'US',
        formatted: m['formatted'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'street': street,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
        'formatted': formatted,
      };
}

class VenueLocation {
  final double lat;
  final double lng;
  final String geohash;

  const VenueLocation({this.lat = 0, this.lng = 0, this.geohash = ''});

  factory VenueLocation.fromMap(Map<String, dynamic> m) => VenueLocation(
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        geohash: m['geohash'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
      };
}

class VenueStats {
  final double avgRating;
  final int ratingCount;
  final int upcomingShowCount;
  final int totalShowCount;

  const VenueStats({
    this.avgRating = 0,
    this.ratingCount = 0,
    this.upcomingShowCount = 0,
    this.totalShowCount = 0,
  });

  factory VenueStats.fromMap(Map<String, dynamic> m) => VenueStats(
        avgRating: (m['avgRating'] as num?)?.toDouble() ?? 0,
        ratingCount: m['ratingCount'] ?? 0,
        upcomingShowCount: m['upcomingShowCount'] ?? 0,
        totalShowCount: m['totalShowCount'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'avgRating': avgRating,
        'ratingCount': ratingCount,
        'upcomingShowCount': upcomingShowCount,
        'totalShowCount': totalShowCount,
      };
}