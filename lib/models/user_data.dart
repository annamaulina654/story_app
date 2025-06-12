class User {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final String? bio;

  User({
    required this.id,
    required this.firebaseUid,
    required this.username,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
    );
  }
}
