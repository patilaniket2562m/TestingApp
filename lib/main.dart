import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// 🔥 BACKGROUND HANDLER (MANDATORY for kill state)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔥 REQUIRED
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// 🔥 Analytics (IMPORTANT FIX)
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  await setupNotifications();

  runApp(const MyApp());
}

Future<void> setupNotifications() async {
  /// 🔔 Local notification init
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      print("Notification clicked!");
    },
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// 🔥 Permission
  await messaging.requestPermission();

  /// 🔥 AUTO INIT (VERY IMPORTANT)
  await messaging.setAutoInitEnabled(true);

  /// 🔥 TOPIC SUBSCRIBE (for Firebase Console targeting)
  await messaging.subscribeToTopic("all_users");

  /// 🔥 TOKEN (for testing)
  String? token = await messaging.getToken();
  print("🔥 FCM TOKEN: $token");
}

/// 🔔 LOCAL NOTIFICATION (FOREGROUND)
Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails details =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    details,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String input = "";
  String result = "0";
  String title = "Loading...";

  @override
  void initState() {
    super.initState();

    fetchTitle();

    /// 🔥 FOREGROUND (APP OPEN)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔥 Foreground notification");

      showLocalNotification(
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Body",
      );
    });

    /// 🔥 CLICK EVENT
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔥 User tapped notification");
    });
  }

  /// 🔥 Firestore title fetch
  void fetchTitle() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('calculator')
          .get();

      setState(() {
        title = (doc.data() != null && doc.data()!['title'] != null)
            ? doc.data()!['title']
            : "Calculator";
      });
    } catch (e) {
      setState(() {
        title = "Calculator";
      });
    }
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == "C") {
        input = "";
        result = "0";
      } else if (value == "=") {
        calculate();
      } else {
        input += value;
      }
    });
  }

  void calculate() {
    try {
      String finalInput =
      input.replaceAll('×', '*').replaceAll('÷', '/');

      double res = 0;

      if (finalInput.contains('+')) {
        var parts = finalInput.split('+');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a + b);
      } else if (finalInput.contains('-')) {
        var parts = finalInput.split('-');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a - b);
      } else if (finalInput.contains('*')) {
        var parts = finalInput.split('*');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a * b);
      } else if (finalInput.contains('/')) {
        var parts = finalInput.split('/');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a / b);
      } else {
        res = double.parse(finalInput);
      }

      setState(() {
        result = res.toString();
      });
    } catch (e) {
      setState(() {
        result = "Error";
      });
    }
  }

  Widget buildButton(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => onButtonClick(text),
          child: Text(text, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20),
              child: Text(input, style: const TextStyle(fontSize: 28)),
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(20),
            child: Text(
              result,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          Row(children: [buildButton("7"), buildButton("8"), buildButton("9"), buildButton("÷")]),
          Row(children: [buildButton("4"), buildButton("5"), buildButton("6"), buildButton("×")]),
          Row(children: [buildButton("1"), buildButton("2"), buildButton("3"), buildButton("-")]),
          Row(children: [buildButton("C"), buildButton("0"), buildButton("="), buildButton("+")]),
        ],
      ),
    );
  }
}