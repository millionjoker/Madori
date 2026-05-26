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

  // factory Door.fromJson(Map<String, dynamic> json) {
  //   return Door(
  //     center: Offset(
  //       (json['CenterX'] as num).toDouble(),
  //       (json['CenterY'] as num).toDouble(),
  //     ),
  //     radius: (json['Radius'] as num).toDouble(),
  //     startAngle: (json['StartAngle'] as num).toDouble(),
  //     endAngle: (json['EndAngle'] as num).toDouble(),
  //     color: _parseColor(json['Color']),
  //   );
  // }
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
    );
  }
}

Color _parseColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}
