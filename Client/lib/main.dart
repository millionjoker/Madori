import 'package:flutter/material.dart';
import '../services/json_loader.dart';
import '../widgets/map_view.dart';
import 'package:path_provider/path_provider.dart';
import 'services/state_log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Flutterの初期化を待つために必要

  // ★ logs.jsonl を作るためのテストログ（1回だけ実行）
  final service = StateLogService();
  await service.appendLog("test1", "startup", true);
  await service.syncLogsToServer(); 
  printAppDir();
  runApp(const MyApp());
}

void printAppDir() async {
  final dir = await getApplicationDocumentsDirectory();
  print("保存先フォルダ: ${dir.path}");
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
