import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'gps_tracking_page.dart';
import 'local_notifications.dart';

final navigatorKey = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotifications.init();

  // var initialNotification =
  // await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  // if (initialNotification?.didNotificationLaunchApp == true) {
  //   // LocalNotifications.onClickNotification.stream.listen((event) {
  //   Future.delayed(Duration(seconds: 1), () {
  //     // print(event);
  //     navigatorKey.currentState!.pushNamed('/',
  //         arguments: initialNotification?.notificationResponse?.payload);
  //   });
  // }

  await Firebase.initializeApp();
  await _checkLocationPermission();
}

Future<void> _checkLocationPermission() async {
  // Check if location permission is already granted
  var status = await Permission.location.status;
  if (status.isGranted) {
    // Permission already granted, proceed with launching the app
    runApp(const MyApp());
  } else {
    // Request permission
    var result = await Permission.location.request();
    if (result.isGranted) {
      // Permission granted, proceed with launching the app
      runApp(const MyApp());
    }else if (status.isDenied) {
      // Permission is denied, request it
      await Permission.location.request();
      exit(0);
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, open app settings
      await openAppSettings();
      exit(0);
    } else if (status.isLimited) {
      // Permission is limited, request it
      await Permission.location.request();
      exit(0);
    } else if (status.isRestricted) {
      // Permission is restricted, open app settings
      await openAppSettings();
      exit(0);
    }
    else {
      // Permission denied, show GUI text and exit the app
      runApp(const PermissionDeniedScreen());
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Tracking System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GPS permission is required to use this app.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}