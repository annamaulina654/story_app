import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:story_app/firebase_options.dart';
import 'screens/splash_screen.dart'; 
import 'package:provider/provider.dart'; 
import 'package:story_app/services/follow_service.dart';
import 'package:story_app/providers/follow_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final followService = FollowService(baseUrl: 'http://localhost:3000/api');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => FollowStatusProvider(followService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
      },
    );
  }
}