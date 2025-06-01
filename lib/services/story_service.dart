import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feed_item_data.dart'; 

class StoryService {
  final String _kApiBaseUrl; 

  StoryService(this._kApiBaseUrl);

  Future<List<FeedItemData>> fetchStories() async {
    final response = await http.get(Uri.parse('$_kApiBaseUrl/stories'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      final List<FeedItemData> stories = data.map((json) => FeedItemData.fromJson(json)).toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    } else {
      throw Exception('Gagal memuat cerita: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> createStory({
    required String description,
    required String? location,
    required String firebaseUid,
    required String mediaData, 
    double? latitude,
    double? longitude,
  }) async {
    final url = '$_kApiBaseUrl/api/stories';
    final requestBody = {
      'description': description,
      'location': location,
      'firebase_uid': firebaseUid,
      'media_data': mediaData,
      'latitude': latitude,
      'longitude': longitude,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decodedResponse = jsonDecode(response.body);
      throw Exception('Failed to create story: ${decodedResponse['message'] ?? response.statusCode}');
    }
  }

  Future<void> updateStory({
    required int storyId, 
    required String description,
    required String? location,
    required String firebaseUid,
    String? mediaData, 
    double? latitude,
    double? longitude,
  }) async {
    final url = '$_kApiBaseUrl/api/stories/$storyId'; 
    final requestBody = {
      'description': description,
      'location': location,
      'firebase_uid': firebaseUid,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (mediaData != null) {
      requestBody['media_data'] = mediaData;
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decodedResponse = jsonDecode(response.body);
      throw Exception('Failed to update story: ${decodedResponse['message'] ?? response.statusCode}');
    }
  }

  Future<void> deleteStory(String storyId, String firebaseUid) async {
    final response = await http.delete(
      Uri.parse('$_kApiBaseUrl/stories/$storyId?firebase_uid=$firebaseUid'),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Gagal menghapus postingan: ${errorBody['message'] ?? response.body}');
    }
  }

  Future<void> followUser(String followerFirebaseUid, String followedFirebaseUid) async {
    final response = await http.post(
      Uri.parse('$_kApiBaseUrl/api/follow'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'follower_firebase_uid': followerFirebaseUid,
        'followed_firebase_uid': followedFirebaseUid,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 409) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Gagal mengikuti pengguna: ${errorBody['message'] ?? response.body}');
    }
  }
}