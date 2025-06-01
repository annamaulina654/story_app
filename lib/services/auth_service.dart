import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String _kApiBaseUrl = 'http://localhost:3000/api'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> registerUserWithFirebase({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendFirebaseEmailVerification(User user) async {
    await user.sendEmailVerification();
  }

  Future<void> registerUserInMySQL({
    required String firebaseUid,
    required String username,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_kApiBaseUrl/register_user'), 
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'firebase_uid': firebaseUid,
          'username': username,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        print('User data registered in MySQL successfully for UID: $firebaseUid');
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Failed to register user data in MySQL: ${responseBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error registering user data in MySQL: $e');
      rethrow; 
    }
  }

  Future<void> deleteFirebaseUser() async {
    if (_auth.currentUser != null) {
      try {
        await _auth.currentUser!.delete();
        print('Firebase user deleted due to MySQL registration failure.');
      } on FirebaseAuthException catch (e) {
        print('Failed to delete Firebase user: ${e.message}');
      } catch (e) {
        print('Unexpected error during Firebase user deletion: $e');
      }
    }
  }

  Future<Map<String, dynamic>> loginUserWithFirebaseAndMySQL({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        throw Exception('User not found after Firebase login.');
      }

      await user.reload();
      user = _auth.currentUser; 

      if (user == null) {
        throw Exception('User not found after reload.');
      }

      if (!user.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email Anda (${user.email}) belum diverifikasi. Silakan cek kotak masuk Anda.',
        );
      }

      print('Firebase user authenticated and email verified. Fetching profile from MySQL...');
      final response = await http.get(Uri.parse('$_kApiBaseUrl/users/${user.uid}')); 

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('User data from MySQL: $userData');
        return userData; 
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Failed to fetch user profile from MySQL: ${responseBody['message'] ?? response.body}');
      }
    } on FirebaseAuthException catch (e) {
      rethrow; 
    } catch (e) {
      print('Error in loginUserWithFirebaseAndMySQL: $e');
      rethrow; 
    }
  }

  Future<void> resendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else if (user == null) {
      throw Exception("No authenticated user found to send verification email.");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}