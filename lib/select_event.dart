import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_page.dart';

class SelectEvent extends StatelessWidget {
  final List<CameraDescription> cameras;
  const SelectEvent({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('種目選択'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text(
              '種目を選択してください',
            ),
            ElevatedButton(
              child: const Text('スクワット'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => (SquatCamPage(title: 'スクワット', cameras: cameras,))),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}