import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'select_event.dart';

List<CameraDescription> cams = [];
DateTime _focusedDay = DateTime.now();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cams = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
  // runApp(const CameraApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Supporting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Workout Supporting'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Out Supporting'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 4, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
          ),
          ElevatedButton(
            child: const Text('トレーニングを開始する'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SelectEvent(cameras: cams)),
              );
            },
          )
        ],
      ),
    );
  }
}