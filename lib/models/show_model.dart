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
  final List<String> genres;
  final double? coverCharge;
  final String currency;
  final String ageRestriction;
  final String ticketUrl;
  final String description;
  final String flyerUrl;
  final String promoter;
  final String status;
  final String titleLower;
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
    this.coverCharge,
    this.currency = 'USD',
    this.ageRestriction = 'all-ages',
    this.ticketUrl = '',
    this.description = '',
    this.flyerUrl = '',
    this.promoter = '',
    this.status = 'active',
    this.titleLower = '',
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
      coverCharge: (data['coverCharge'] as num?)?.toDouble(),
      currency: data['currency'] ?? 'USD',
      ageRestriction: data['ageRestriction'] ?? 'all-ages',
      ticketUrl: data['ticketUrl'] ?? '',
      description: data['description'] ?? '',
      flyerUrl: data['flyerUrl'] ?? '',
      promoter: data['promoter'] ?? '',
      status: data['status'] ?? 'active',
      titleLower: data['titleLower'] ?? '',
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
        'startTime':
            startTime != null ? Timestamp.fromDate(startTime!) : null,
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'lineup': lineup.map((e) => e.toMap()).toList(),
        'genres': genres,
        'coverCharge': coverCharge,
        'currency': currency,
        'ageRestriction': ageRestriction,
        'ticketUrl': ticketUrl,
        'description': description,
        'flyerUrl': flyerUrl,
        'promoter': promoter,
        'status': status,
        'titleLower': title.toLowerCase(),
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