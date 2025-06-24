import 'package:story_app/models/feed_item_data.dart';

class UserProfile {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String? fullName;
  final String? profileImageUrl;
  final String? bio;
  final int storyCount;
  final int followerCount;
  final int followingCount;
  final List<FeedItemData> stories; 

  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.username,
    required this.email,
    this.fullName,
    this.profileImageUrl,
    this.bio,
    required this.storyCount,
    required this.followerCount,
    required this.followingCount,
    required this.stories,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var storiesList = json['stories'] as List? ?? [];
    List<FeedItemData> stories = storiesList.map((i) => FeedItemData.fromJson(i)).toList();

    return UserProfile(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      storyCount: json['storyCount'] ?? 0,
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      stories: stories,
    );
  }
}