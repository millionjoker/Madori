import 'package:flutter/material.dart';
import '../../../models/room.dart';
import 'map_view_platform.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class MapView extends StatefulWidget {
  final List<Room> rooms;
  const MapView({super.key, required this.rooms});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  double scale = 1.0;
  Offset offset = Offset.zero;
  Set<Room> selectedRooms = {};
  //late AnimationController _controller;
  //late Animation<double> _angleAnim;
  Map<int, AnimationController> doorControllers = {};

  @override
  void initState() {
    super.initState();
    //_controller = AnimationController(
    //  vsync: this,
    //  duration: const Duration(milliseconds: 800),
    //);

    setupWheelListener(
      () {
        setState(() {});
      },
      () {
        return scale;
      },
      (newScale) {
        scale = newScale;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ ここに追加（Chrome で Ticker が止まっていないか確認）
    //print("TickerMode = ${TickerMode.of(context)}");

    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          scale = details.scale;
          offset += details.focalPointDelta;
        });
      },
      onTapUp: (details) {
        final local = (details.localPosition - offset) / scale;
        // ドアのタップ判定
        for (int roomIndex = 0; roomIndex < widget.rooms.length; roomIndex++) {
          final room = widget.rooms[roomIndex];
          for (int doorIndex = 0; doorIndex < room.doors.length; doorIndex++) {
            final door = room.doors[doorIndex];
            //print("Door center = ${door.center}, radius = ${door.radius}");
            final key = roomIndex * 1000 + doorIndex;

            if (_isInsideDoor(local, door)) {
              print("=== Door tapped (before animation) ===");
              print("startAngle = ${door.startAngle}");
              print("endAngle = ${door.endAngle}");
              print("currentEndAngle = ${door.currentEndAngle}");
              print("isOpen = ${door.isOpen}");
              print("======================================");

              // ★ 以前の controller があれば破棄
              if (doorControllers.containsKey(key)) {
                doorControllers[key]!.dispose();
              }

              // ★ 新しい controller を毎回作る（これが Web で必要）
              final controller = AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: kIsWeb ? 5000 : 500),
              );
              doorControllers[key] = controller;

              // final controller = doorControllers.putIfAbsent(
              //   key,
              //   () => AnimationController(
              //     vsync: this,
              //     duration: const Duration(milliseconds: 300),
              //   ),
              // );

              final from = door.currentEndAngle;
              final to = door.isOpen ? door.endAngle : door.startAngle;
              late Animation<double>? animation;

              animation =
                  Tween<double>(begin: from, end: to).animate(
                      CurvedAnimation(
                        parent: controller,
                        curve: Curves.easeOut,
                      ),
                    )
                    ..addListener(() {
                      setState(() {
                        door.currentEndAngle = animation!.value;
                        print("anim value = ${animation!.value}");
                      });
                    })
                    ..addStatusListener((status) {
                      if (status == AnimationStatus.completed) {
                        door.isOpen = !door.isOpen;
                        print("anim completed, isOpen = ${door.isOpen}");
                      }
                    });

              //controller.reset();
              controller.forward(from: 0);

              return;
            }
          }
        }
        //部屋のタップ判定
        for (final room in widget.rooms) {
          if (_isInsidePolygon(local, room.points)) {
            //setState(() => selected = room);
            setState(() {
              if (selectedRooms.contains(room)) {
                selectedRooms.remove(room); //再クリックで解除
              } else {
                selectedRooms.add(room);
              }
            });
            //print("部屋をタップしました");
            return;
          }
        }
      },
      child: CustomPaint(
        painter: _MapPainter(
          rooms: widget.rooms,
          scale: scale,
          offset: offset,
          selectedRooms: selectedRooms,
        ),
        child: Container(),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in doorControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  //クリック判定（部屋）
  bool _isInsidePolygon(Offset p, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].dx, yi = poly[i].dy;
      final xj = poly[j].dx, yj = poly[j].dy;

      final intersect =
          ((yi > p.dy) != (yj > p.dy)) &&
          (p.dx < (xj - xi) * (p.dy - yi) / (yj - yi + 0.00001) + xi);

      if (intersect) inside = !inside;
    }
    return inside;
  }

  //クリック判定（ドア）
  bool _isInsideDoor(Offset point, Door door) {
    final dx = point.dx - door.center.dx;
    final dy = point.dy - door.center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance > door.radius) return false;

    double angle = atan2(dy, dx) * 180 / pi;
    if (angle < 0) angle += 360;
    double start = door.startAngle % 360;
    double end = door.endAngle % 360;
    // 角度範囲チェック（start > end の場合も考慮）
    if (start < end) {
      return angle >= start && angle <= end;
    } else {
      return angle >= start || angle <= end;
    }
  }
}

class _MapPainter extends CustomPainter {
  final List<Room> rooms;
  final double scale;
  final Offset offset;
  final Set<Room> selectedRooms;

  _MapPainter({
    required this.rooms,
    required this.scale,
    required this.offset,
    required this.selectedRooms,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    //全ての部屋を描く
    for (final room in rooms) {
      final paint = Paint()
        //..color = room == selected ? Colors.black12 : room.color
        ..color = selectedRooms.contains(room) ? Colors.black12 : room.color
        ..style = PaintingStyle.fill;

      final path = Path()..addPolygon(room.points, true);
      canvas.drawPath(path, paint);

      // 境界線（枠線）を描く
      final borderPaint = Paint()
        ..color =
            const Color(0xFFBDB76B) // #bdb76b
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(path, borderPaint);

      //部屋名
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.name,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, room.points.first);
    }

    // ② 全てのドアを描く（部屋とは別ループ）
    for (final room in rooms) {
      for (final door in room.doors) {
        final doorPaint = Paint()
          ..color = door.color
          ..style = PaintingStyle.fill;

        final rect = Rect.fromCircle(center: door.center, radius: door.radius);
        final sweep = (door.currentEndAngle - door.startAngle) * pi / 180;
        final safeSweep = sweep.abs().clamp(0.0001, 2 * pi);

        final doorPath = Path()
          ..moveTo(door.center.dx, door.center.dy)
          ..arcTo(rect, door.startAngle * pi / 180, safeSweep, false)
          ..close();

        canvas.drawPath(doorPath, doorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
