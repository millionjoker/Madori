import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/room.dart';

class LocalStateService {
  // 保存先ファイル名
  static const String fileName = "state.json";
  // アプリ専用フォルダのパスを取得
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$fileName");
  }

  // ★ 部屋リストを保存するメソッド（あなたが必要としているもの）
  Future<void> saveRooms(List<Room> rooms) async {
    final file = await _getLocalFile();
    // Room → JSON へ変換
    final jsonList = rooms.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<List<Room>> loadRooms() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];
      final text = await file.readAsString();
      final jsonList = jsonDecode(text) as List;
      return jsonList.map((j) => Room.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }
}
