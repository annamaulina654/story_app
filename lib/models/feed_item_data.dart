class FeedItemData {
  final int id;
  final String description;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? location;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String authorFirebaseUid;
  final int likesCount;
  final int commentsCount;

  FeedItemData({
    required this.id,
    required this.description,
    required this.photoUrl,
    required this.createdAt,
    this.location,
    this.updatedAt,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.authorFirebaseUid,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory FeedItemData.fromJson(Map<String, dynamic> json) {
    final parsedCreatedAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now();

    final parsedUpdatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;

    return FeedItemData(
      id: json['id'] as int,
      description: (json['description'] as String?) ?? '',
      photoUrl: (json['photo_url'] as String?) ?? 'https://via.placeholder.com/150',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      location: json['location'] as String?,
      authorUsername: (json['author_username'] as String?) ?? 'Pengguna Tidak Dikenal',
      authorAvatarUrl: (json['author_avatar_url'] as String?) ?? 'assets/images/user-profile.png',
      authorFirebaseUid: (json['author_firebase_uid'] as String?) ?? '',
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
    );
  }
}