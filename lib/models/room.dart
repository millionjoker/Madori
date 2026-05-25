import 'package:flutter/material.dart';

class Room {
  final String name;
  final Color color;
  final List<Offset> points;
  final List<Door> doors;

  Room({
    required this.name,
    required this.color,
    required this.points,
    required this.doors,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      name: json['Name'],
      color: _parseColor(json['BackgroundColor']),
      points: (json['Points'] as List)
          .map(
            (p) =>
                Offset((p['X'] as num).toDouble(), (p['Y'] as num).toDouble()),
          )
          .toList(),
      doors: json['Doors'] == null
          ? []
          : (json['Doors'] as List).map((d) => Door.fromJson(d)).toList(),
    );
  }
}

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
    return Door(
      center: Offset(
        (json['CenterX'] as num).toDouble(),
        (json['CenterY'] as num).toDouble(),
      ),
      radius: (json['Radius'] as num).toDouble(),
      startAngle: (json['StartAngle'] as num).toDouble(),
      endAngle: (json['EndAngle'] as num).toDouble(),
      color: _parseColor(json['Color']),
    );
  }
}

Color _parseColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // 透明度を追加
  }
  return Color(int.parse(hexColor, radix: 16));
}
