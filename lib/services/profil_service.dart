import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_data.dart';  // model UserProfile seperti yang kita buat sebelumnya

class ProfileService {
  final String _kApiBaseUrl;

  ProfileService(this._kApiBaseUrl);

  Future<UserProfile> fetchUserProfile(String firebaseUid) async {
    final url = '$_kApiBaseUrl/profile/$firebaseUid';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserProfile.fromJson(data);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to load user profile: ${errorBody['message'] ?? response.statusCode}');
    }
  }

  Future<void> updateUserProfile({
    required String firebaseUid,
    required String username,
    required String email,
    String? fullName,
    String? profileImageUrl,
    String? bio,
  }) async {
    final url = '$_kApiBaseUrl/profile/$firebaseUid';

    final requestBody = {
      'username': username,
      'email': email,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'bio': bio,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to update user profile: ${errorBody['message'] ?? response.statusCode}');
    }
  }
}
