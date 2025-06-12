// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:story_app/firebase_options.dart';
// import 'screens/splash_screen.dart'; 
// import 'package:provider/provider.dart'; 
// import 'package:story_app/services/follow_service.dart';
// import 'package:story_app/providers/follow_status_provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   final followService = FollowService(baseUrl: 'http://localhost:3000/api');

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(
//           create: (context) => FollowStatusProvider(followService),
//         ),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false, 
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/follow_service.dart';
import 'providers/follow_status_provider.dart';

// Notifikasi & timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Inisialisasi notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi notifikasi & timezone
  tz.initializeTimeZones();
  await _initNotifications();

  // Jadwalkan notifikasi harian
  await scheduleDailyNotification();

  // Service untuk follow
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

// Inisialisasi notifikasi
Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

// Penjadwalan notifikasi harian (jam 20:30)
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

// Fungsi bantu: menentukan waktu berikutnya
tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

// Widget utama
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        // Tambahkan route lain jika diperlukan
      },
    );
  }
}

