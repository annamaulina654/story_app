import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/follow_service.dart';
import 'providers/follow_status_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  tz.initializeTimeZones();
  await _initNotifications();
  await scheduleDailyNotification();

  final followService = FollowService(baseUrl: 'http://localhost:3000/api');

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

Future<void> scheduleDailyNotification() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Story Reminder',
    'Jangan lupa buat story hari ini!',
    _nextInstanceOfTime(21, 00),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Pengingat harian untuk membuat story',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
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

