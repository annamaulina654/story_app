// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFfpX5bl3ICEzrC-KFF-n24ahvfusl-LE',
    appId: '1:1074304070607:web:b4e3bc33a9c4dfce29d8ba',
    messagingSenderId: '1074304070607',
    projectId: 'coba-4c9b1',
    authDomain: 'coba-4c9b1.firebaseapp.com',
    databaseURL: 'https://coba-4c9b1-default-rtdb.firebaseio.com',
    storageBucket: 'coba-4c9b1.firebasestorage.app',
    measurementId: 'G-4E9H9QE9WV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEVuFKBRgDWUHdExeJ1PXoxP_k0ZYZfQ4',
    appId: '1:1074304070607:android:f4483aaccdae5d8a29d8ba',
    messagingSenderId: '1074304070607',
    projectId: 'coba-4c9b1',
    databaseURL: 'https://coba-4c9b1-default-rtdb.firebaseio.com',
    storageBucket: 'coba-4c9b1.firebasestorage.app',
  );
}
