import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feed_item_data.dart';

class StoryService {
  final String _kApiBaseUrl;
  final SupabaseClient _supabaseClient;
  final String _supabaseStorageBucket = 'story.images';
  StoryService(this._kApiBaseUrl, this._supabaseClient);

  String? _extractPathFromPublicUrl(String publicUrl, String bucketName) {
    if (!publicUrl.contains('/storage/v1/object/public/$bucketName/')) {
      return null;
    }
    final publicPathPrefix = '/storage/v1/object/public/$bucketName/';
    final startIndex = publicUrl.indexOf(publicPathPrefix);
    if (startIndex == -1) return null;
    return publicUrl.substring(startIndex + publicPathPrefix.length);
  }

  Future<String?> _uploadMediaToSupabase(
      XFile pickedFile,
      String firebaseUid,
      {String? oldPublicImageUrl}) async {
    final File imageFile = File(pickedFile.path);
    final String originalFileName = p.basename(pickedFile.path);
    String finalFilePathInBucket;

    finalFilePathInBucket = 'story_images/${firebaseUid}_${DateTime.now().millisecondsSinceEpoch}_$originalFileName';

    try {
      if (oldPublicImageUrl != null && oldPublicImageUrl.isNotEmpty) {
        final oldFilePathInBucket = _extractPathFromPublicUrl(oldPublicImageUrl, _supabaseStorageBucket);
        if (oldFilePathInBucket != null) {
          try {
            await _supabaseClient.storage
              .from(_supabaseStorageBucket)
              .remove([oldFilePathInBucket]);
          } on StorageException catch (e) {
            throw Exception('Error deleting old image from Flutter: ${e.message}. Might not exist or no permission.');
          }
        }
      }

      await _supabaseClient.storage
          .from(_supabaseStorageBucket)
          .upload(
            finalFilePathInBucket,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      final String publicUrl = _supabaseClient.storage.from(_supabaseStorageBucket).getPublicUrl(finalFilePathInBucket);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Failed to upload image to storage from Flutter: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during image upload from Flutter: ${e.toString()}');
    }
  }

  Future<List<FeedItemData>> fetchStories() async {
    try {
      final response = await http.get(Uri.parse('$_kApiBaseUrl/stories'));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((json) => FeedItemData.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to load stories: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load stories: ${e.toString()}');
    }
  }

  Future<void> createStory({
    required String description,
    required String firebaseUid,
    XFile? mediaFile,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    String? publicImageUrl;
    if (mediaFile != null) {
      publicImageUrl = await _uploadMediaToSupabase(mediaFile, firebaseUid);
    }

    final url = '$_kApiBaseUrl/stories';
    final requestBody = {
      'firebase_uid': firebaseUid,
      'description': description,
      'public_image_url': publicImageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decodedResponse = jsonDecode(response.body);
        throw Exception('Failed to add story: ${decodedResponse['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create story: ${e.toString()}');
    }
  }

  Future<void> updateStory({
    required int storyId,
    required String description,
    required String firebaseUid,
    XFile? mediaFile,
    String? oldImageUrl,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    String? newMediaUrlToSend;

    if (mediaFile != null) {
      newMediaUrlToSend = await _uploadMediaToSupabase(mediaFile, firebaseUid, oldPublicImageUrl: oldImageUrl);
    } else {
      newMediaUrlToSend = oldImageUrl;
    }

    final url = '$_kApiBaseUrl/stories/$storyId';
    final requestBody = {
      'description': description,
      'location': location,
      'firebase_uid': firebaseUid,
      'public_image_url': newMediaUrlToSend,
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decodedResponse = jsonDecode(response.body);
        throw Exception('Failed to update story: ${decodedResponse['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update story: ${e.toString()}');
    }
  }

  Future<void> deleteStory(String storyId, String firebaseUid, {String? mediaUrl}) async {
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      final filePathInBucket = _extractPathFromPublicUrl(mediaUrl, _supabaseStorageBucket);
      if (filePathInBucket != null) {
        try {
          await _supabaseClient.storage
              .from(_supabaseStorageBucket)
              .remove([filePathInBucket]);
        } on StorageException catch (e) {
          throw Exception('Error deleting image from Supabase Storage (Flutter): ${e.message}');
        } catch (e) {
          throw Exception('General error deleting image from Supabase Storage (Flutter): $e');
        }
      } else {
        throw Exception('Warning: Could not extract file path for image from URL: $mediaUrl');
      }
    } else {
      throw Exception('No mediaUrl provided or empty. Skipping image deletion from storage.');
    }

    final response = await http.delete(
      Uri.parse('$_kApiBaseUrl/stories/$storyId?firebase_uid=$firebaseUid'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to delete post from backend: ${errorBody['message'] ?? response.body}');
    }
  }

  Future<void> followUser(String followerUid, String followedUid) async {
    final url = Uri.parse('$_kApiBaseUrl/api/follow');
    final body = jsonEncode({
      'follower_firebase_uid': followerUid,
      'followed_firebase_uid': followedUid,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: body,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 409) {
      final error = jsonDecode(response.body);
      throw Exception('Failed to follow user: ${error['message'] ?? response.body}');
    }
  }
}