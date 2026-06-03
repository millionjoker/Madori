import 'package:flutter/material.dart';

class Door {
  final int id;
  Offset center;
  double radius;
  double startAngle; // 閉じた角度（基準）
  double endAngle; // 開いた角度（目標）
  double currentAngle; // 現在の角度（startAngle → endAngle の途中）
  bool isOpen;
  Color color;

  Door({
    required this.id,
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.endAngle,
    required this.color,
    this.isOpen = false,
  }) : currentAngle = isOpen ? endAngle : startAngle;

  factory Door.fromJson(Map<String, dynamic> json) {
    final start = (json['StartAngle'] as num).toDouble();
    final end = (json['EndAngle'] as num).toDouble();
    final isOpen = json['IsOpen'] ?? false;

    return Door(
      id: json['Id'],
      center: Offset(
        (json['CenterX'] as num).toDouble(),
        (json['CenterY'] as num).toDouble(),
      ),
      radius: (json['Radius'] as num).toDouble(),
      startAngle: start,
      endAngle: end,
      color: _parseColor(json['Color']),
      isOpen: isOpen,
    );
  }

  // ★ Door → JSON（Room.toJson() がこれを呼ぶ）
  Map<String, dynamic> toJson() {
    return {
      "Id": id,
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
