// ignore_for_file: unused_local_variable

import 'package:checkit_off/app/splashscreen/splashscreen.dart';
import 'package:checkit_off/user_auth/presentation/widgets/root.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final Logger logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase Core
    await Firebase.initializeApp();
    logger.i('Firebase initialized successfully.');

    // Initialize Firebase App Check with Play Integrity provider
    logger.i('Activating Firebase App Check...');
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
    logger.i('Firebase App Check activated.');

    // Initialize Remote Config
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.setDefaults(<String, dynamic>{
      'FIREBASE_API_KEY': 'default_api_key',
      'FIREBASE_APP_ID': 'default_app_id',
      'FIREBASE_MESSAGING_SENDER_ID': 'default_messaging_sender_id',
      'FIREBASE_PROJECT_ID': 'default_project_id',
      'FIREBASE_STORAGE_BUCKET': 'default_storage_bucket',
    });

    // Fetch and activate remote config
    bool updated = await remoteConfig.fetchAndActivate();
    if (updated) {
      logger.i('Remote config values updated.');
    } else {
      logger.i('Remote config values are already up-to-date.');
    }

    // Retrieve parameters
    final String apiKey = remoteConfig.getString('FIREBASE_API_KEY');
    final String appId = remoteConfig.getString('FIREBASE_APP_ID');
    final String messagingSenderId = remoteConfig.getString('FIREBASE_MESSAGING_SENDER_ID');
    final String projectId = remoteConfig.getString('FIREBASE_PROJECT_ID');
    final String storageBucket = remoteConfig.getString('FIREBASE_STORAGE_BUCKET');

    logger.i('Remote Config Parameters - API Key: $apiKey, App ID: $appId');

    // Initialize time zones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/London'));
    logger.i('Time zone set to Europe/London.');

    // Initialize notifications
    await _initializeNotifications();
  } catch (e) {
    logger.e('Error during initialization: $e');
  }

  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  try {
    // Create notification channel
    await _initializeNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    logger.i('Initializing local notifications...');
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          logger.i('Notification tapped with payload: $payload');
        }
      },
    );
    logger.i('Local notifications initialized.');
  } catch (e) {
    logger.e('Error initializing notifications: $e');
  }
}

Future<void> _initializeNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'task_reminders', // ID
    'Task Reminders', // Name
    description: 'Notifications for task reminders and deadlines.', // Description
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
  );

  try {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    logger.i('Notification channel created: ${channel.name}');
  } catch (e) {
    logger.e('Error creating notification channel: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Splashscreen(
        child: Root(),
      ),
    );
  }
}
