import 'package:flutter/material.dart';

class PaintStroke {
  final List<Offset> points;
  Color color;

  PaintStroke({required this.points, required this.color});
}

class StrokePainter extends CustomPainter {
  final List<PaintStroke> strokes;

  StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
