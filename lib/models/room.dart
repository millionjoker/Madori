import 'package:flutter/material.dart';
import 'door.dart';
import 'furniture.dart';

class Room {
  final String name;
  final Color color;
  final List<Offset> points;
  final List<Door> doors;
  final List<Furniture> furnitures;

  Room({
    required this.name,
    required this.color,
    required this.points,
    required this.doors,
    required this.furnitures,
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

      furnitures: json['Furnitures'] == null
          ? []
          : (json['Furnitures'] as List)
                .map((f) => Furniture.fromJson(f))
                .toList(),
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
