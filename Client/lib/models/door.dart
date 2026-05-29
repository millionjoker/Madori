import 'package:flutter/material.dart';

class Door {
  Offset center;
  double radius;
  double startAngle;
  double endAngle;
  double currentEndAngle;
  Color color;
  bool isOpen;

  Door({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.endAngle,
    required this.color,
    this.isOpen = false,
  }) : currentEndAngle = endAngle;

  factory Door.fromJson(Map<String, dynamic> json) {
    final start = (json['StartAngle'] as num).toDouble();
    final end = (json['EndAngle'] as num).toDouble();
    return Door(
      center: Offset(
        (json['CenterX'] as num).toDouble(),
        (json['CenterY'] as num).toDouble(),
      ),
      radius: (json['Radius'] as num).toDouble(),
      startAngle: start, // ← 入れ替え
      endAngle: end, // ← 入れ替え
      color: _parseColor(json['Color']),
      isOpen: json['IsOpen'] ?? false,
    );
  }

  // ★ Door → JSON（Room.toJson() がこれを呼ぶ）
  Map<String, dynamic> toJson() {
    return {
      "CenterX": center.dx,
      "CenterY": center.dy,
      "Radius": radius,
      "StartAngle": startAngle,
      "EndAngle": endAngle,
      "Color": _colorToHex(color),
      "IsOpen": isOpen,
    };
  }
}

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
