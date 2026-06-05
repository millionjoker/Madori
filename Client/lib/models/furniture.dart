import 'package:flutter/material.dart';

class Furniture {
  final int id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
  bool isOn;

  Furniture({
    required this.id,
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
      id: json['Id'],
      type: json['Type'],
      x: (json['X'] as num).toDouble(),
      y: (json['Y'] as num).toDouble(),
      width: (json['Width'] as num).toDouble(),
      height: (json['Height'] as num).toDouble(),
      color: _parseColor(json['Color']),
      isOn: json['IsOn'] ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "Type": type,
      "X": x,
      "Y": y,
      "Width": width,
      "Height": height,
      "Color": _colorToHex(color),
      "Value": isOn,
    };
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

String _colorToHex(Color c) {
  return "#${c.value.toRadixString(16).padLeft(8, '0')}";
}
