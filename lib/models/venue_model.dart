import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_lat_lng.dart';

class VenueModel {
  final String venueId;
  final String name;
  final String nameLower;
  final String nameNormalized;
  final VenueAddress address;
  final VenueLocation location;
  final List<String> photos;
  final List<String> tags; // Legacy alias of genreTags used by current UI.
  final List<String> genreTags;
  final int? capacity;
  final Map<String, String> contact;
  final String venueType;
  final String seatingType;
  final String ageRestriction;
  final bool hasParking;
  final String transitInfo;
  final String foodDrink;
  final bool isAccessible;
  final String accessibilityNotes;
  final String coverChargeTypical;
  final String websiteUrl;
  final Map<String, String> socialLinks;
  final VenueStats stats;
  final bool isVerified;
  final String? claimedBy;
  final DateTime? claimedAt;
  final String ownerSubscription;
  final bool promoted;
  final DateTime? promotedUntil;
  final double accuracyScore;
  final String submittedBy;
  final String createdBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VenueModel({
    required this.venueId,
    required this.name,
    required this.nameLower,
    this.nameNormalized = '',
    required this.address,
    required this.location,
    this.photos = const [],
    this.tags = const [],
    this.genreTags = const [],
    this.capacity,
    this.contact = const {},
    this.venueType = 'other',
    this.seatingType = 'mixed',
    this.ageRestriction = 'all_ages',
    this.hasParking = false,
    this.transitInfo = '',
    this.foodDrink = 'none',
    this.isAccessible = false,
    this.accessibilityNotes = '',
    this.coverChargeTypical = '',
    this.websiteUrl = '',
    this.socialLinks = const {},
    this.stats = const VenueStats(),
    this.isVerified = false,
    this.claimedBy,
    this.claimedAt,
    this.ownerSubscription = 'free',
    this.promoted = false,
    this.promotedUntil,
    this.accuracyScore = 1.0,
    this.submittedBy = '',
    required this.createdBy,
    this.status = 'pending',
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
      nameNormalized: data['nameNormalized'] ??
          data['name_normalized'] ??
          (data['name'] ?? '').toString().toLowerCase(),
      address: VenueAddress.fromMap(data['address'] ?? {}),
      location: VenueLocation.fromMap(data['location'] ?? {}),
      photos: List<String>.from(data['photos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      genreTags: List<String>.from(
        data['genreTags'] ?? data['genre_tags'] ?? data['tags'] ?? [],
      ),
      capacity: data['capacity'],
      contact: Map<String, String>.from(data['contact'] ?? {}),
      venueType:
          (data['venueType'] ?? data['venue_type'] ?? 'other').toString(),
      seatingType:
          (data['seatingType'] ?? data['seating_type'] ?? 'mixed').toString(),
      ageRestriction:
          (data['ageRestriction'] ?? data['age_restriction'] ?? 'all_ages')
              .toString(),
      hasParking: data['hasParking'] ?? data['has_parking'] ?? false,
      transitInfo:
          (data['transitInfo'] ?? data['transit_info'] ?? '').toString(),
      foodDrink: (data['foodDrink'] ?? data['food_drink'] ?? 'none').toString(),
      isAccessible: data['isAccessible'] ?? data['is_accessible'] ?? false,
      accessibilityNotes:
          (data['accessibilityNotes'] ?? data['accessibility_notes'] ?? '')
              .toString(),
      coverChargeTypical:
          (data['coverChargeTypical'] ?? data['cover_charge_typical'] ?? '')
              .toString(),
      websiteUrl: (data['websiteUrl'] ?? data['website_url'] ?? '').toString(),
      socialLinks: Map<String, String>.from(
          data['socialLinks'] ?? data['social_links'] ?? {}),
      stats: VenueStats.fromMap(data['stats'] ?? {}),
      isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
      claimedBy: data['claimedBy'] ?? data['claimed_by'],
      claimedAt:
          (data['claimedAt'] as Timestamp? ?? data['claimed_at'] as Timestamp?)
              ?.toDate(),
      ownerSubscription:
          (data['ownerSubscription'] ?? data['owner_subscription'] ?? 'free')
              .toString(),
      promoted: data['promoted'] ?? false,
      promotedUntil: (data['promotedUntil'] as Timestamp? ??
              data['promoted_until'] as Timestamp?)
          ?.toDate(),
      accuracyScore:
          (data['accuracyScore'] as num? ?? data['accuracy_score'] as num?)
                  ?.toDouble() ??
              1.0,
      submittedBy: (data['submittedBy'] ??
              data['submitted_by'] ??
              data['createdBy'] ??
              '')
          .toString(),
      createdBy: data['createdBy'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'nameLower': name.toLowerCase(),
        'nameNormalized':
            nameNormalized.isEmpty ? name.toLowerCase() : nameNormalized,
        'address': address.toMap(),
        'location': location.toMap(),
        'photos': photos,
        'tags': tags,
        'genreTags': genreTags.isEmpty ? tags : genreTags,
        'capacity': capacity,
        'contact': contact,
        'venueType': venueType,
        'seatingType': seatingType,
        'ageRestriction': ageRestriction,
        'hasParking': hasParking,
        'transitInfo': transitInfo,
        'foodDrink': foodDrink,
        'isAccessible': isAccessible,
        'accessibilityNotes': accessibilityNotes,
        'coverChargeTypical': coverChargeTypical,
        'websiteUrl': websiteUrl,
        'socialLinks': socialLinks,
        'stats': stats.toMap(),
        'isVerified': isVerified,
        'claimedBy': claimedBy,
        'claimedAt': claimedAt == null ? null : Timestamp.fromDate(claimedAt!),
        'ownerSubscription': ownerSubscription,
        'promoted': promoted,
        'promotedUntil':
            promotedUntil == null ? null : Timestamp.fromDate(promotedUntil!),
        'accuracyScore': accuracyScore,
        'submittedBy': submittedBy.isEmpty ? createdBy : submittedBy,
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
