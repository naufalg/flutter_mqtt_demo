import 'package:flutter/material.dart';
import 'package:mqtt_test/screen/message_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initSP();
  }

  initSP() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT flutter test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MessageScreen(),
    );
  }
}
