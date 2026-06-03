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
import 'package:http/http.dart' as http;

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}

Color darken(Color c, [double amount = .2]) {
  final hsl = HSLColor.fromColor(c);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

double normalize(double angle) {
  angle = angle % 360;
  if (angle < 0) angle += 360;
  return angle;
}

class MapView extends StatefulWidget {
  final List<Room> rooms;
  const MapView({super.key, required this.rooms});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  late List<Room> rooms;
  final localState = LocalStateService();
  final logService = StateLogService();

  double scale = 1.0;
  double baseScale = 1.0;
  Offset offset = Offset.zero;

  Set<Room> selectedRooms = {};
  Furniture? selectedFurniture;
  Map<int, AnimationController> doorControllers = {};

  int pendingCount = 0; // ★ 未送信件数

  // ============================
  // API 呼び出し（失敗しても UI は維持）
  // ============================
  Future<void> sendRoomStateToServer(int roomId, bool isOn) async {
    final url = Uri.parse(
      "http://localhost:5187/rooms/$roomId/${isOn ? "on" : "off"}",
    );
    await http.post(url);
  }

  Future<void> sendDoorStateToServer(
    int roomId,
    int doorId,
    bool isOpen,
  ) async {
    final url = Uri.parse(
      "http://localhost:5187/rooms/$roomId/doors/$doorId/${isOpen ? "open" : "close"}",
    );
    await http.post(url);
  }

  Future<void> sendFurnitureStateToServer(
    int roomId,
    int furnitureId,
    bool isOn,
  ) async {
    final url = Uri.parse(
      "http://localhost:5187/rooms/$roomId/furnitures/$furnitureId/${isOn ? "on" : "off"}",
    );
    await http.post(url);
  }

  // ============================
  // 未送信件数の更新
  // ============================
  Future<void> updatePendingCount() async {
    final count = await logService.getPendingCount();
    setState(() {
      pendingCount = count;
    });
  }

  @override
  void initState() {
    super.initState();
    rooms = widget.rooms;

    // ★ 起動時に未送信件数を読み込む
    updatePendingCount();

    setupWheelListener(
      () => setState(() {}),
      () => scale,
      (newScale) => scale = newScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onScaleStart: (details) {
            baseScale = scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              scale = baseScale * details.scale;
              offset += details.focalPointDelta;
            });
          },
          onTapUp: (details) async {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset local = box.globalToLocal(details.globalPosition);
            final Offset world = (local - offset) / scale;

            // ============================
            // ① 家具
            // ============================
            for (int roomIndex = 0; roomIndex < rooms.length; roomIndex++) {
              final room = rooms[roomIndex];
              for (int fIndex = 0; fIndex < room.furnitures.length; fIndex++) {
                final f = room.furnitures[fIndex];
                final rect = Rect.fromLTWH(f.x, f.y, f.width, f.height);

                if (rect.contains(world)) {
                  setState(() {
                    f.isOn = !f.isOn;
                    rooms = List.from(rooms);
                  });

                  await localState.saveRooms(rooms);

                  await logService.appendLog(
                    "furniture_click",
                    "furniture_${f.id}",
                    f.isOn,
                  );

                  try {
                    await sendFurnitureStateToServer(room.id, f.id, f.isOn);
                    await logService.syncLogsToServer();
                  } catch (_) {}

                  await updatePendingCount();
                  return;
                }
              }
            }

            // ============================
            // ② ドア
            // ============================
            for (int roomIndex = 0; roomIndex < rooms.length; roomIndex++) {
              final room = rooms[roomIndex];
              for (
                int doorIndex = 0;
                doorIndex < room.doors.length;
                doorIndex++
              ) {
                final door = room.doors[doorIndex];
                final key = roomIndex * 1000 + doorIndex;

                if (_isInsideDoor(world, door)) {
                  if (doorControllers.containsKey(key)) {
                    doorControllers[key]!.dispose();
                  }
                  final controller = AnimationController(
                    vsync: this,
                    duration: const Duration(milliseconds: kIsWeb ? 5000 : 500),
                  );
                  doorControllers[key] = controller;

                  final from = door.currentAngle;
                  final to = door.isOpen ? door.startAngle : door.endAngle;

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
                            door.currentAngle = animation!.value;
                            rooms = List.from(rooms);
                          });
                        })
                        ..addStatusListener((status) async {
                          if (status == AnimationStatus.completed) {
                            door.isOpen = !door.isOpen;

                            await localState.saveRooms(rooms);

                            await logService.appendLog(
                              "door_click",
                              "door_${door.id}",
                              door.isOpen,
                            );

                            try {
                              await sendDoorStateToServer(
                                room.id,
                                door.id,
                                door.isOpen,
                              );
                              await logService.syncLogsToServer();
                            } catch (_) {}

                            await updatePendingCount();
                          }
                        });

                  controller.forward(from: 0);
                  return;
                }
              }
            }

            // ============================
            // ③ 部屋
            // ============================
            for (int i = 0; i < rooms.length; i++) {
              final room = rooms[i];
              if (_isInsidePolygon(world, room.points)) {
                final isCurrentlyOn = selectedRooms.contains(room);
                final newValue = !isCurrentlyOn;

                setState(() {
                  room.isOn = newValue;
                  if (isCurrentlyOn) {
                    selectedRooms.remove(room);
                  } else {
                    selectedRooms.add(room);
                  }
                  rooms = List.from(rooms);
                });

                await localState.saveRooms(rooms);

                await logService.appendLog(
                  "room_click",
                  "room_${room.id}",
                  newValue,
                );

                try {
                  await sendRoomStateToServer(room.id, newValue);
                  await logService.syncLogsToServer();
                } catch (_) {}

                await updatePendingCount();
                return;
              }
            }
          },
          child: CustomPaint(
            painter: _MapPainter(
              rooms: rooms,
              scale: scale,
              offset: offset,
              selectedRooms: selectedRooms,
              selectedFurniture: selectedFurniture,
            ),
            child: Container(),
          ),
        ),

        // ============================
        // ★ 未送信件数バッジ
        // ============================
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              pendingCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in doorControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

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

  bool _isInsideDoor(Offset local, Door door) {
    final dx = local.dx - door.center.dx;
    final dy = local.dy - door.center.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > door.radius) return false;

    double angle = atan2(dy, dx) * 180 / pi;
    angle = (angle + 360) % 360;

    double start = (door.startAngle + 360) % 360;
    double end = (door.endAngle + 360) % 360;

    double diff = (end - start + 540) % 360 - 180;
    double mid = start + diff / 2;
    mid = (mid + 360) % 360;

    double d = (angle - mid + 540) % 360 - 180;
    d = d.abs();

    return d <= 45;
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

    // 部屋
    for (final room in rooms) {
      final roomColor = room.isOn ? room.color : hexToColor("#DCDCDC");

      final paint = Paint()
        ..color = roomColor
        ..style = PaintingStyle.fill;

      final path = Path()..addPolygon(room.points, true);
      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = const Color(0xFFBDB76B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);

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

    // ドア
    for (final room in rooms) {
      for (final door in room.doors) {
        final doorPath = buildDoorPath(
          door.center,
          door.radius,
          door.startAngle,
          door.currentAngle,
        );

        canvas.drawPath(
          doorPath,
          Paint()
            ..color = door.color
            ..style = PaintingStyle.fill,
        );

        if (door.currentAngle != door.endAngle) {
          final closedPath = buildClosedArc(
            door.center,
            door.radius,
            door.startAngle,
            door.endAngle,
          );

          final dashed = dashPath(
            closedPath,
            dashArray: CircularIntervalList<double>([4, 2]),
          );

          canvas.drawPath(
            dashed,
            Paint()
              ..color = door.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }

    // 家具
    for (final room in rooms) {
      for (final f in room.furnitures) {
        final rect = Rect.fromLTWH(f.x, f.y, f.width, f.height);

        final furnitureColor = f.isOn ? f.color : hexToColor("#F5F5F5");

        final paint = Paint()
          ..color = furnitureColor
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);

        final border = Paint()
          ..color = darken(furnitureColor, 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(rect, border);

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

  Path buildDoorPath(
    Offset center,
    double radius,
    double startAngle,
    double currentAngle,
  ) {
    final startRad = startAngle * pi / 180;
    final currentRad = currentAngle * pi / 180;

    final startPoint = Offset(
      center.dx + radius * cos(startRad),
      center.dy + radius * sin(startRad),
    );

    final endPoint = Offset(
      center.dx + radius * cos(currentRad),
      center.dy + radius * sin(currentRad),
    );

    return Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(startPoint.dx, startPoint.dy)
      ..arcToPoint(
        endPoint,
        radius: Radius.circular(radius),
        clockwise: _isClockwise(startAngle, currentAngle),
      )
      ..close();
  }

  Path buildClosedArc(
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
  ) {
    final startRad = startAngle * pi / 180;
    final endRad = endAngle * pi / 180;

    final startPoint = Offset(
      center.dx + radius * cos(startRad),
      center.dy + radius * sin(startRad),
    );

    final endPoint = Offset(
      center.dx + radius * cos(endRad),
      center.dy + radius * sin(endRad),
    );

    return Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..arcToPoint(
        endPoint,
        radius: Radius.circular(radius),
        clockwise: _isClockwise(startAngle, endAngle),
      );
  }

  bool _isClockwise(double start, double end) {
    double diff = (end - start) % 360;
    if (diff < 0) diff += 360;
    return diff < 180;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
