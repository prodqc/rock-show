import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String avatarUrl;
  final String bio;
  final String city;
  final String state;
  final double? locationLat;
  final double? locationLng;
  final List<String> favoriteGenres;
  final Map<String, String> links;
  final String role;
  final int trustLevel; // Legacy field kept for backward compatibility.
  final double trustScore;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String subscriptionTier;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    this.email = '',
    required this.displayName,
    required this.username,
    this.avatarUrl = '',
    this.bio = '',
    this.city = '',
    this.state = '',
    this.locationLat,
    this.locationLng,
    this.favoriteGenres = const [],
    this.links = const {},
    this.role = 'user',
    this.trustLevel = 1,
    this.trustScore = 0.0,
    this.isVerified = false,
    this.verifiedAt,
    this.subscriptionTier = 'free',
    this.stats = const UserStats(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: (data['email'] ?? data['email_address'] ?? '').toString(),
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      locationLat: (data['locationLat'] as num? ?? data['location_lat'] as num?)
          ?.toDouble(),
      locationLng: (data['locationLng'] as num? ?? data['location_lng'] as num?)
          ?.toDouble(),
      favoriteGenres: List<String>.from(data['favoriteGenres'] ?? []),
      links: Map<String, String>.from(data['links'] ?? {}),
      role: data['role'] ?? 'user',
      trustLevel: data['trustLevel'] ?? 1,
      trustScore: (data['trustScore'] as num? ?? data['trust_score'] as num?)
              ?.toDouble() ??
          0.0,
      isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
      verifiedAt: (data['verifiedAt'] as Timestamp? ??
              data['verified_at'] as Timestamp?)
          ?.toDate(),
      subscriptionTier:
          (data['subscriptionTier'] ?? data['subscription_tier'] ?? 'free')
              .toString(),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'city': city,
        'state': state,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'favoriteGenres': favoriteGenres,
        'links': links,
        'role': role,
        'trustLevel': trustLevel,
        'trustScore': trustScore,
        'isVerified': isVerified,
        'verifiedAt':
            verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
        'subscriptionTier': subscriptionTier,
        'stats': stats.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserModel copyWith({
    String? email,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? city,
    String? state,
    double? locationLat,
    double? locationLng,
    List<String>? favoriteGenres,
    Map<String, String>? links,
    String? role,
    int? trustLevel,
    double? trustScore,
    bool? isVerified,
    DateTime? verifiedAt,
    String? subscriptionTier,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      state: state ?? this.state,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      links: links ?? this.links,
      role: role ?? this.role,
      trustLevel: trustLevel ?? this.trustLevel,
      trustScore: trustScore ?? this.trustScore,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      stats: stats ?? this.stats,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class UserStats {
  final int followerCount;
  final int followingCount;
  final int venuesCreated;
  final int showsCreated;
  final int reviewsWritten;

  const UserStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.venuesCreated = 0,
    this.showsCreated = 0,
    this.reviewsWritten = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
        followerCount: map['followerCount'] ?? 0,
        followingCount: map['followingCount'] ?? 0,
        venuesCreated: map['venuesCreated'] ?? 0,
        showsCreated: map['showsCreated'] ?? 0,
        reviewsWritten: map['reviewsWritten'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'followerCount': followerCount,
        'followingCount': followingCount,
        'venuesCreated': venuesCreated,
        'showsCreated': showsCreated,
        'reviewsWritten': reviewsWritten,
      };
}
