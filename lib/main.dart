import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:story_app/screens/feed_page.dart';
import 'package:story_app/screens/welcome_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/follow_service.dart';
import 'providers/follow_status_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

late final SupabaseClient supabase;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://sldiuwljdwdteegzjnbh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsZGl1d2xqZHdkdGVlZ3pqbmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE1NDIsImV4cCI6MjA2NDE1NzU0Mn0.HH0Lgvc9W3S7vJDUoIMDMiRB550lOoWe3HUEtFvtf1s',
  );
  supabase = Supabase.instance.client;

  await _initNotifications();

  final followService = FollowService(
    baseUrl: 'https://story-app-api-eta.vercel.app/api',
    notificationsPlugin: flutterLocalNotificationsPlugin, // <- Dikirim ke service
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FollowStatusProvider(followService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
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
        '/auth': (context) => const AuthGate(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const FeedPage();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
