import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:story_app/models/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ProfileService {
  final String _kApiBaseUrl = 'https://story-app-api-eta.vercel.app/api';
  final SupabaseClient _supabaseClient;

  final String _storageBucket = 'story.images';
  final String _profileFolder = 'profile_pictures';

  ProfileService(this._supabaseClient);

  Future<UserProfile> fetchUserProfile(String firebaseUid) async {
    final url = '$_kApiBaseUrl/profile/$firebaseUid';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  Future<String?> uploadProfileImage(File imageFile, String firebaseUid) async {
    final fileName = p.basename(imageFile.path);
    final filePath = '$_profileFolder/${firebaseUid}_$fileName';

    try {
      await _supabaseClient.storage.from(_storageBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _supabaseClient.storage.from(_storageBucket).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> deleteProfilePictureFromSupabase(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      final urlParts = imageUrl.split('$_storageBucket/');
      if (urlParts.length > 1) {
        final filePath = urlParts[1];
        await _supabaseClient.storage.from(_storageBucket).remove([filePath]);
      }
    } catch (e) {
      print("Supabase delete warning (can be ignored): $e");
    }
  }

  Future<void> updateUserProfile({
    required String firebaseUid,
    required String username,
    String? fullName,
    String? bio,
    String? newImageUrl, 
    bool isImageDeleted = false,
  }) async {
    final url = '$_kApiBaseUrl/profile/$firebaseUid';

    final requestBody = {
      'username': username,
      'full_name': fullName,
      'bio': bio,
    };

    if (isImageDeleted) {
      requestBody['profile_image_url'] = null;
    } else if (newImageUrl != null) {
      requestBody['profile_image_url'] = newImageUrl;
    }
    
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update user profile via API');
    }
  }
}