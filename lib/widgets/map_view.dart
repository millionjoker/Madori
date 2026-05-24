import 'package:flutter/material.dart';
import '../../../models/room.dart';
import 'map_view_platform.dart';

class MapView extends StatefulWidget {
  final List<Room> rooms;
  const MapView({super.key, required this.rooms});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double scale = 1.0;
  Offset offset = Offset.zero;

  Room? selected;

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
      onTapUp: (details) {
        final local = (details.localPosition - offset) / scale;

        for (final room in widget.rooms) {
          if (_isInsidePolygon(local, room.points)) {
            setState(() => selected = room);
            break;
          }
        }
      },
      child: CustomPaint(
        painter: _MapPainter(
          rooms: widget.rooms,
          scale: scale,
          offset: offset,
          selected: selected,
        ),
        child: Container(),
      ),
    );
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
}

class _MapPainter extends CustomPainter {
  final List<Room> rooms;
  final double scale;
  final Offset offset;
  final Room? selected;

  _MapPainter({
    required this.rooms,
    required this.scale,
    required this.offset,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    //全ての部屋を描く
    for (final room in rooms) {
      final paint = Paint()
        ..color = room == selected ? Colors.black12 : room.color
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

        final doorPath = Path()
          ..moveTo(door.center.dx, door.center.dy)
          ..arcTo(
            rect,
            door.startAngle * 3.14159 / 180,
            (door.endAngle - door.startAngle) * 3.14159 / 180,
            false,
          )
          ..close();

        canvas.drawPath(doorPath, doorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
