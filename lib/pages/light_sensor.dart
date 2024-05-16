import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:permission_handler/permission_handler.dart';

class LightSensorPage extends StatefulWidget {
  const LightSensorPage({super.key});

  @override
  State<LightSensorPage> createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  late final StreamSubscription<int> _lightSensorSubscription;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  int _animationValue = 0;

  final Duration _animationDuration = const Duration(seconds: 3);

  final Color _baseColor = Color.fromARGB(255, 255, 255, 255);

  Color _backgroundColor = Colors.white;

  // Darkens the given color by a specified amount.
  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final double lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkAndRequestPermissions();

    LightSensor.hasSensor().then((hasSensor) {
      if (hasSensor) {
        _lightSensorSubscription = LightSensor.luxStream().listen((lux) {
          setState(() {
            _animationValue = lux;
            _backgroundColor = _darken(_baseColor, 0.5 - lux / 1000);
          });

          // Notify user when light level is high
          if (lux > 200) {
            _showNotification(
                'HIGH LIGHT LEVEL', 'The light level is above 200 lux.');
          }
        });
      } else {
        print('Device does not have a light sensor.');
      }
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    // Check if the necessary permissions are granted
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      // Request permissions if they're not granted
      Map<Permission, PermissionStatus> statuses = await [
        Permission.notification,
      ].request();
      print(statuses[Permission.notification]);
    }
  }

  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'app_icon'); // Change to your notification icon name
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'light_sensor_channel',
      'Light Sensor',
      channelDescription: 'Notification Channel for Light Sensor',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'app_icon',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _lightSensorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          "Light Sensor",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Light Level: $_animationValue lux',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _backgroundColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: _animationDuration,
              width: 20 + _animationValue * 0.5,
              height: 20 + _animationValue * 0.5,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 50 + _animationValue * 0.2,
                  color: _backgroundColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
