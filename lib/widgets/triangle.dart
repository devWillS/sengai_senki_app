import 'package:flutter/material.dart';

class Triangle extends CustomPainter {
  const Triangle({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    paint.color = Colors.transparent;
    var rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // 三角（塗りつぶし）
    paint.color = color;
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
