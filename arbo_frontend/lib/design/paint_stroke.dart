import 'package:flutter/material.dart';

class PaintStroke {
  final Path path;
  final Color color;

  PaintStroke({required this.path, required this.color});
}

class PathPainter extends CustomPainter {
  final List<PaintStroke> strokes;

  PathPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(stroke.path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
