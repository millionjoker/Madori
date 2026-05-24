import 'package:flutter/material.dart';
import '../services/json_loader.dart';
import '../widgets/map_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: JsonLoader.loadRooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text("Map Viewer")),
            body: MapView(rooms: snapshot.data!),
          );
        },
      ),
    );
  }
}
