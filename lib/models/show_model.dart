import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_lat_lng.dart';

class ShowModel {
  final String showId;
  final String venueId;
  final String venueName;
  final VenueGeo venueLocation;
  final String title;
  final DateTime date;
  final DateTime? doorsTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<LineupAct> lineup;
  final List<String> genres; // Legacy alias used by current UI.
  final List<String> genreTags;
  final double? coverCharge;
  final double? priceAdvance;
  final double? priceDoor;
  final bool isFree;
  final String currency;
  final String ageRestriction;
  final String ticketUrl;
  final String description;
  final String flyerUrl;
  final String promoter;
  final String status;
  final String trustLevel;
  final String sourceUrl;
  final String sourceImageUrl;
  final int corroborationCount;
  final bool promoted;
  final DateTime? promotedUntil;
  final bool isArchived;
  final String titleLower;
  final String submittedBy;
  final String createdBy;
  final ShowStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShowModel({
    required this.showId,
    required this.venueId,
    required this.venueName,
    required this.venueLocation,
    required this.title,
    required this.date,
    this.doorsTime,
    this.startTime,
    this.endTime,
    this.lineup = const [],
    this.genres = const [],
    this.genreTags = const [],
    this.coverCharge,
    this.priceAdvance,
    this.priceDoor,
    this.isFree = false,
    this.currency = 'USD',
    this.ageRestriction = 'all_ages',
    this.ticketUrl = '',
    this.description = '',
    this.flyerUrl = '',
    this.promoter = '',
    this.status = 'community_reported',
    this.trustLevel = 'community',
    this.sourceUrl = '',
    this.sourceImageUrl = '',
    this.corroborationCount = 0,
    this.promoted = false,
    this.promotedUntil,
    this.isArchived = false,
    this.titleLower = '',
    this.submittedBy = '',
    required this.createdBy,
    this.stats = const ShowStats(),
    required this.createdAt,
    required this.updatedAt,
  });

  AppLatLng get appLatLng => AppLatLng(
        latitude: venueLocation.lat,
        longitude: venueLocation.lng,
      );

  factory ShowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShowModel(
      showId: doc.id,
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueLocation: VenueGeo.fromMap(data['venueLocation'] ?? {}),
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      doorsTime: (data['doorsTime'] as Timestamp?)?.toDate(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      lineup: (data['lineup'] as List<dynamic>?)
              ?.map((e) => LineupAct.fromMap(e))
              .toList() ??
          [],
      genres: List<String>.from(data['genres'] ?? []),
      genreTags: List<String>.from(
        data['genreTags'] ?? data['genre_tags'] ?? data['genres'] ?? [],
      ),
      coverCharge: (data['coverCharge'] as num?)?.toDouble(),
      priceAdvance:
          (data['priceAdvance'] as num? ?? data['price_advance'] as num?)
              ?.toDouble(),
      priceDoor:
          (data['priceDoor'] as num? ?? data['price_door'] as num?)?.toDouble(),
      isFree: data['isFree'] ?? data['is_free'] ?? false,
      currency: data['currency'] ?? 'USD',
      ageRestriction:
          (data['ageRestriction'] ?? data['age_restriction'] ?? 'all_ages')
              .toString(),
      ticketUrl: data['ticketUrl'] ?? '',
      description: data['description'] ?? '',
      flyerUrl: data['flyerUrl'] ?? '',
      promoter: data['promoter'] ?? '',
      status: (data['status'] ?? 'community_reported').toString(),
      trustLevel:
          (data['trustLevel'] ?? data['trust_level'] ?? 'community').toString(),
      sourceUrl: (data['sourceUrl'] ?? data['source_url'] ?? '').toString(),
      sourceImageUrl:
          (data['sourceImageUrl'] ?? data['source_image_url'] ?? '').toString(),
      corroborationCount: (data['corroborationCount'] as num? ??
                  data['corroboration_count'] as num?)
              ?.toInt() ??
          0,
      promoted: data['promoted'] ?? false,
      promotedUntil: (data['promotedUntil'] as Timestamp? ??
              data['promoted_until'] as Timestamp?)
          ?.toDate(),
      isArchived: data['isArchived'] ?? data['is_archived'] ?? false,
      titleLower: data['titleLower'] ?? '',
      submittedBy: (data['submittedBy'] ??
              data['submitted_by'] ??
              data['createdBy'] ??
              '')
          .toString(),
      createdBy: data['createdBy'] ?? '',
      stats: ShowStats.fromMap(data['stats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'venueId': venueId,
        'venueName': venueName,
        'venueLocation': venueLocation.toMap(),
        'title': title,
        'date': Timestamp.fromDate(date),
        'doorsTime': doorsTime != null ? Timestamp.fromDate(doorsTime!) : null,
        'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'lineup': lineup.map((e) => e.toMap()).toList(),
        'genres': genres,
        'genreTags': genreTags.isEmpty ? genres : genreTags,
        'coverCharge': coverCharge,
        'priceAdvance': priceAdvance,
        'priceDoor': priceDoor,
        'isFree': isFree,
        'currency': currency,
        'ageRestriction': ageRestriction,
        'ticketUrl': ticketUrl,
        'description': description,
        'flyerUrl': flyerUrl,
        'promoter': promoter,
        'status': status,
        'trustLevel': trustLevel,
        'sourceUrl': sourceUrl,
        'sourceImageUrl': sourceImageUrl,
        'corroborationCount': corroborationCount,
        'promoted': promoted,
        'promotedUntil':
            promotedUntil == null ? null : Timestamp.fromDate(promotedUntil!),
        'isArchived': isArchived,
        'titleLower': title.toLowerCase(),
        'submittedBy': submittedBy.isEmpty ? createdBy : submittedBy,
        'createdBy': createdBy,
        'stats': stats.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

class VenueGeo {
  final double lat;
  final double lng;
  final String geohash;

  const VenueGeo({this.lat = 0, this.lng = 0, this.geohash = ''});

  factory VenueGeo.fromMap(Map<String, dynamic> m) => VenueGeo(
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        geohash: m['geohash'] ?? '',
      );

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'geohash': geohash};
}

class LineupAct {
  final String name;
  final int order;

  const LineupAct({required this.name, required this.order});

  factory LineupAct.fromMap(Map<String, dynamic> m) =>
      LineupAct(name: m['name'] ?? '', order: m['order'] ?? 0);

  Map<String, dynamic> toMap() => {'name': name, 'order': order};
}

class ShowStats {
  final double avgRating;
  final int ratingCount;

  const ShowStats({this.avgRating = 0, this.ratingCount = 0});

  factory ShowStats.fromMap(Map<String, dynamic> m) => ShowStats(
        avgRating: (m['avgRating'] as num?)?.toDouble() ?? 0,
        ratingCount: m['ratingCount'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'avgRating': avgRating,
        'ratingCount': ratingCount,
      };
}
