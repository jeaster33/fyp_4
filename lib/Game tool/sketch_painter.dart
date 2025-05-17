import 'package:flutter/material.dart';

// Custom painter for drawing freehand sketches on the canvas.
class SketchPainter extends CustomPainter {
  final List<Offset> points; // List of points representing the drawing.
  final Offset lineBreak; // Special separator to indicate breaks between lines.

  // Constructor for SketchPainter that initializes the points and lineBreak.
  SketchPainter(this.points, this.lineBreak);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint object to define the drawing style.
    Paint paint = Paint()
      ..color = Colors.black // Black color for the lines.
      ..strokeWidth = 3 // Line thickness.
      ..strokeCap = StrokeCap.round; // Rounded ends for the lines.

    // Iterate through the points to draw the lines.
    for (int i = 0; i < points.length - 1; i++) {
      // Check if the current point and the next point are not line breaks.
      if (points[i] != lineBreak && points[i + 1] != lineBreak) {
        // Draw a line between consecutive points.
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint the canvas when the points list changes.
    return true;
  }
}

