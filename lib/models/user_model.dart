import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final String avatarUrl;
  final String bio;
  final String city;
  final String state;
  final List<String> favoriteGenres;
  final Map<String, String> links;
  final String role;
  final int trustLevel;
  final bool isVerified;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    this.avatarUrl = '',
    this.bio = '',
    this.city = '',
    this.state = '',
    this.favoriteGenres = const [],
    this.links = const {},
    this.role = 'user',
    this.trustLevel = 1,
    this.isVerified = false,
    this.stats = const UserStats(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      favoriteGenres: List<String>.from(data['favoriteGenres'] ?? []),
      links: Map<String, String>.from(data['links'] ?? {}),
      role: data['role'] ?? 'user',
      trustLevel: data['trustLevel'] ?? 1,
      isVerified: data['isVerified'] ?? false,
      stats: UserStats.fromMap(data['stats'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'city': city,
        'state': state,
        'favoriteGenres': favoriteGenres,
        'links': links,
        'role': role,
        'trustLevel': trustLevel,
        'isVerified': isVerified,
        'stats': stats.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserModel copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? city,
    String? state,
    List<String>? favoriteGenres,
    Map<String, String>? links,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      state: state ?? this.state,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      links: links ?? this.links,
      role: role,
      trustLevel: trustLevel,
      stats: stats,
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