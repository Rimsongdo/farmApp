import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tryapp/loading.dart';
import 'package:tryapp/login.dart';
import 'package:tryapp/home.dart';
import 'package:tryapp/profil.dart';


// Configuration des notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Gère les messages en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Message reçu en arrière-plan : ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Gère les messages en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialisation des notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // iOS permissions
  if (await FirebaseMessaging.instance.isSupported()) {
    await FirebaseMessaging.instance.requestPermission();
  }

  // Get the FCM token for debugging or storing
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gestion des messages en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan : ${message.data}');
      if (message.notification != null) {
        showNotification(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? 'Aucune description',
        );
      }
    });

    // Gestion des messages cliqués
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification cliquée : ${message.data}');
      // Navigate to the HomePage when the notification is clicked
      Navigator.pushNamed(context, '/home');
    });

    return MaterialApp(
      title: 'Flutter Login Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoadingPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => const MainPage(),
        '/profil': (context) => const ProfilePage(),
        
      },
    );
  }
}

// Fonction pour afficher une notification locale
void showNotification(String title, String body) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'default_channel_id', 'Default Notifications',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(
    0, // ID de la notification
    title, // Titre de la notification
    body, // Corps de la notification
    platformChannelSpecifics,
  );
}
