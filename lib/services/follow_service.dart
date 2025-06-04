import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowService {
  final String baseUrl; 
  FollowService({required this.baseUrl});

  Future<bool> isFollowing({
    required String followerUid,
    required String followedUid,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/follows/status?follower_firebase_uid=$followerUid&followed_firebase_uid=$followedUid'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['isFollowing'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> followUser({
    required String followerUid,
    required String followedUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/follow'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'follower_firebase_uid': followerUid,
          'followed_firebase_uid': followedUid,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> unfollowUser({
    required String followerUid,
    required String followedUid,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/unfollow'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'follower_firebase_uid': followerUid,
          'followed_firebase_uid': followedUid,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}