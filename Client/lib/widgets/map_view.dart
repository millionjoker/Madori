import 'package:flutter/material.dart';
import '../../../models/room.dart';
import '../../../models/door.dart';
import '../../../models/furniture.dart';
import 'map_view_platform.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_drawing/path_drawing.dart';
import '../services/local_state_service.dart';
import '../services/state_log_service.dart';

class MapView extends StatefulWidget {
  final List<Room> rooms;
  const MapView({super.key, required this.rooms});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  final localState = LocalStateService();
  double scale = 1.0;
  Offset offset = Offset.zero;
  Set<Room> selectedRooms = {};
  Furniture? selectedFurniture;
  Map<int, AnimationController> doorControllers = {};
  final logService = StateLogService();
  
  @override
  void initState() {
    super.initState();
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
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          scale = details.scale;
          offset += details.focalPointDelta;
        });
      },
      onTapUp: (details) async {
        final local = (details.localPosition - offset) / scale;

        // 家具のタップ判定（ドアより先に行う）
        for (int roomIndex = 0; roomIndex < widget.rooms.length; roomIndex++) {
          final room = widget.rooms[roomIndex];

          for (int fIndex = 0; fIndex < room.furnitures.length; fIndex++) {
            final f = room.furnitures[fIndex];

            final rect = Rect.fromLTWH(f.x, f.y, f.width, f.height);

            if (rect.contains(local)) {
              setState(() {
                f.isOn = !f.isOn;
              });
              // ★ 家具状態を保存
              await localState.saveRooms(widget.rooms);
              return; // 家具に当たったら他の判定はしない
            }
          }
        }

        // ドアのタップ判定
        for (int roomIndex = 0; roomIndex < widget.rooms.length; roomIndex++) {
          final room = widget.rooms[roomIndex];
          for (int doorIndex = 0; doorIndex < room.doors.length; doorIndex++) {
            final door = room.doors[doorIndex];
            final key = roomIndex * 1000 + doorIndex;

            if (_isInsideDoor(local, door)) {
              if (doorControllers.containsKey(key)) {
                doorControllers[key]!.dispose();
              }
              // 新しい controller を毎回作る（これが Web で必要）
              final controller = AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: kIsWeb ? 5000 : 500),
              );
              doorControllers[key] = controller;

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
                      });
                    })
                    ..addStatusListener((status) async {
                      if (status == AnimationStatus.completed) {
                        door.isOpen = !door.isOpen;
                        // ★ ドア状態を保存
                        await localState.saveRooms(widget.rooms);
                      }
                    });

              //controller.reset();
              controller.forward(from: 0);

              return;
            }
          }
        }
        //部屋のタップ判定
        for (int i = 0; i < widget.rooms.length; i++) {
          final room = widget.rooms[i];
          if (_isInsidePolygon(local, room.points)) {
            // ★ 部屋クリックの操作ログを記録
            final isCurrentlyOn = selectedRooms.contains(room);
            final newValue = !isCurrentlyOn;            
            await logService.appendLog(
              "room_click",     // eventType
              "room_$i",        // deviceId（部屋番号を文字列化）
              newValue,             // value
            );
            await logService.syncLogsToServer();          
            setState(() {
              if (isCurrentlyOn) {
                selectedRooms.remove(room);
              } else {
                selectedRooms.add(room);
              }
            });

            // ★ 必要なら部屋状態を保存
            await localState.saveRooms(widget.rooms);

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
          selectedFurniture: selectedFurniture,
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
  final Furniture? selectedFurniture;

  _MapPainter({
    required this.rooms,
    required this.scale,
    required this.offset,
    required this.selectedRooms,
    required this.selectedFurniture,
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

        // ★ 閉じているときは「扉の線」だけ描く
        if (door.currentEndAngle != door.endAngle) {
          final doorPaint2 = Paint()
            ..color = door.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          final doorPath = Path()
            ..moveTo(door.center.dx, door.center.dy)
            ..arcTo(rect, door.startAngle * pi / 180, pi / 2, false);
          //..close();
          final dashed = dashPath(
            doorPath,
            dashArray: CircularIntervalList<double>([4, 2]),
          );
          canvas.drawPath(dashed, doorPaint2);
        }
      }
    }

    // ③ 家具（Furnitures）を描く
    for (final room in rooms) {
      for (final f in room.furnitures) {
        final rect = Rect.fromLTWH(f.x, f.y, f.width, f.height);

        final isSelected = (selectedFurniture == f);

        // 塗りつぶし
        final paint = Paint()
          ..color = f.isOn
              ? Colors.green.withOpacity(0.6) // ← ON の色（例：緑）
              : f.color.withOpacity(0.6) // ← OFF の色（元の色）
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);

        // 枠線
        final border = Paint()
          ..color = f.isOn ? Colors.green : Colors.brown
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRect(rect, border);

        // 机の種類（Type）を小さく表示したい場合
        final textPainter = TextPainter(
          text: TextSpan(
            text: f.type,
            style: const TextStyle(color: Colors.black, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(f.x + 2, f.y + 2));
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
