import 'package:flutter/material.dart';
import 'door.dart';
import 'furniture.dart';

class Room {
  final int id;
  final String name;
  final Color color;
  final List<Offset> points;
  final List<Door> doors;
  final List<Furniture> furnitures;
  bool isOn;

  Room({
    required this.id,
    required this.name,
    required this.color,
    required this.points,
    required this.doors,
    required this.furnitures,
    this.isOn = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['Id'],
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
      isOn: json['IsOn'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "Name": name,
      "BackgroundColor": _colorToHex(color),
      "Points": points.map((p) => {"X": p.dx, "Y": p.dy}).toList(),
      "Doors": doors.map((d) => d.toJson()).toList(),
      "Furnitures": furnitures.map((f) => f.toJson()).toList(),
      "IsOn": isOn,
    };
  }
}

Color _parseColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // 透明度を追加
  }
  return Color(int.parse(hexColor, radix: 16));
}

// ★ Color → #RRGGBB 変換
String _colorToHex(Color c) {
  return "#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}";
}
