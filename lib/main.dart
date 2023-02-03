import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'select_event.dart';
import './database_helper.dart';
import 'package:intl/intl.dart';

List<CameraDescription> cams = [];
DateTime _focusedDay = DateTime.now();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cams = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }
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
  final dbHelper = DatabaseHelper.instance;
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  List<Map<String, dynamic>> _trainingData = [];

  void _refreshJournals() async {
    DateFormat outputFormat = DateFormat('yyyy-MM-dd');
    String date = outputFormat.format(_focused);

    final data = await dbHelper.getTrainingData(date);
    setState(() {
      _trainingData = data;
    });
  }

  void _deleteItem(int id) async {
    await dbHelper.delete(id);
    setState(() {
      _refreshJournals();
    });
  }

  String _convert(String date) {
    List<String> before = date.split("-");
    String after = '${before[0]}年${before[1]}月${before[2]}日';
    return after;
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }


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
            selectedDayPredicate: (day) {
              return isSameDay(_selected, day);
            },
            onDaySelected: (selected, focused) {
              if (!isSameDay(_selected, selected)) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                  _refreshJournals();
                });
              }
            },
            focusedDay: _focused,
          ),
          ElevatedButton(
            child: const Text("トレーニングを開始する"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SelectEvent(cameras: cams)),
              );
            },
          ),
          ListView.builder(
              shrinkWrap: true,
              itemCount: _trainingData.length,
              itemBuilder: (context, index) => Card(
                color: Colors.blue[300],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(_trainingData[index]["training"], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("${_trainingData[index]["count"]}回", style: const TextStyle(color: Colors.white)),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => {
                              setState(() {
                                _deleteItem(_trainingData[index]['_id']);
                              })
                            }
                        ),
                      ],
                    ),
                  ),
                )
              )
          )
        ],
      ),
    );
  }
}