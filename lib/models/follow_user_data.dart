class FollowUser {
  final String firebaseUid;
  final String username;
  final String? fullName;
  final String? profileImageUrl;
  bool isFollowing;

  FollowUser({
    required this.firebaseUid,
    required this.username,
    this.fullName,
    this.profileImageUrl,
    required this.isFollowing,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      fullName: json['full_name'],
      profileImageUrl: json['profile_image_url'],
      isFollowing: (json['is_following'] == 1 || json['is_following'] == true),
    );
  }
}