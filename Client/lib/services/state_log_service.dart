import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<String> getLogFilePath() async {
  if (kIsWeb) {
    // Web ではファイルシステムが使えないので、空文字を返す or ログを無効化
    return '';
  }
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/logs.jsonl';
}

class StateLogService {
  // ★ アプリ専用フォルダのパスを取得
  Future<String> _getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // ★ state.json を読み込む（なければ初期データを返す）
  Future<Map<String, dynamic>> loadState() async {
    final dir = await _getAppDir();
    final file = File('$dir/state.json');

    if (!await file.exists()) {
      return {"rooms": {}, "doors": {}, "desks": {}};
    }

    final text = await file.readAsString();
    return jsonDecode(text);
  }

  // ★ state.json を更新（部屋・ドア・机の ON/OFF と時刻）
  Future<void> updateState(String type, String id, bool value) async {
    final state = await loadState();
    final now = DateTime.now().toIso8601String();

    state[type] ??= {};
    state[type][id] = {"on": value, "updated": now};

    final dir = await _getAppDir();
    final file = File('$dir/state.json');
    await file.writeAsString(jsonEncode(state));
  }

  Future<void> appendLog(String eventType, String deviceId, bool value) async {
    final log = {
      "deviceId": deviceId,
      "eventTime": DateTime.now().toUtc().toIso8601String(),
      "eventType": eventType,
      "payload": {"value": value},
    };

    // --- Web の場合はファイルシステムが使えない ---
    if (kIsWeb) {
      print("WEB LOG: ${jsonEncode(log)}");
      return;
    }

    // --- Windows / iPad / Android の場合はこちら ---
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/logs.jsonl');

    await file.writeAsString(jsonEncode(log) + '\n', mode: FileMode.append);
  }

  // ★ 1回の操作で state.json と logs.jsonl を両方更新
  Future<void> toggleItem(String type, String id, bool value) async {
    await updateState(type, id, value);
    await appendLog(type, id, value);
  }

  //ログファイルを読む 2026-5-29
  Future<List<String>> readLogLines() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/logs.jsonl');
    if (!await file.exists()) {
      return [];
    }
    final lines = await file.readAsLines();
    return lines;
  }

  Future<bool> sendLogLineToServer(String line) async {
    final url = Uri.parse('http://localhost:5187/logs');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: line,
      );
      print("レスポンスコード: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print("レスポンスボディ: ${response.body}");
      } else {
        print("レスポンスボディ: <empty>");
      }
      return response.statusCode == 201;
    } catch (e) {
      print("送信中に例外発生: $e");
      return false;
    }
  }

  Future<void> removeSentLine(String line) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/logs.jsonl');
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    lines.remove(line);
    await file.writeAsString(lines.join('\n') + '\n');
  }

  Future<void> syncLogsToServer() async {
    print("同期開始");
    try {
      final rawLines = await readLogLines();
      final lines = rawLines
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      print("ログ行数（空行除外後）: ${lines.length}");
      for (final line in lines) {
        print("送信中: $line");
        final ok = await sendLogLineToServer(line);
        if (ok) {
          print("送信成功 → 削除: $line");
          await removeSentLine(line);
        } else {
          print("送信失敗 → 残す: $line");
          break;
        }
      }
    } catch (e, st) {
      print("同期中に例外発生: $e");
      print(st);
    }
    print("同期終了");
  }

  Future<int> getPendingCount() async {
    final lines = await readLogLines();
    return lines.map((e) => e.trim()).where((e) => e.isNotEmpty).length;
  }
}
