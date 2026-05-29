import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../models/room.dart';

class JsonLoader {
  static Future<List<Room>> loadRooms() async {
    final jsonStr = await rootBundle.loadString('assets/madori.json');
    final List data = json.decode(jsonStr);
    return data.map((e) => Room.fromJson(e)).toList();
  }
}
