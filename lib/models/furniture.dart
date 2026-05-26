import 'package:flutter/material.dart';
import 'room.dart'; // 色パース関数を共有したい場合はこれを使う
// もし room.dart の _parseColor を使わないなら、
// このファイルにも _parseColor をコピーしても良い。

class Furniture {
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
  bool isOn;

  Furniture({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.isOn = false,
  });

  factory Furniture.fromJson(Map<String, dynamic> json) {
    return Furniture(
      type: json['Type'],
      x: (json['X'] as num).toDouble(),
      y: (json['Y'] as num).toDouble(),
      width: (json['Width'] as num).toDouble(),
      height: (json['Height'] as num).toDouble(),
      color: _parseColor(json['Color']),
      isOn: json['IsOn'] ?? false,
    );
  }
}

// ここに色パース関数を置くか、room.dart のものを使うか選べる
Color _parseColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}
