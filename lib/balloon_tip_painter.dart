import 'package:flutter/material.dart';

class BalloonTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double cornerRadius = 12.0;
    const double arrowWidth = 16.0;
    const double arrowHeight = 10.0;
    
    // Calculate arrow position (bottom center)
    final double arrowX = size.width / 2;
    final double arrowY = size.height - arrowHeight;

    // Create the balloon path
    final path = Path();
    
    // Start from top-left corner
    path.moveTo(cornerRadius, 0);
    
    // Top edge
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Right edge
    path.lineTo(size.width, arrowY - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, arrowY),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Bottom edge to arrow start
    path.lineTo(arrowX + arrowWidth / 2, arrowY);
    
    // Arrow tip
    path.lineTo(arrowX, size.height);
    path.lineTo(arrowX - arrowWidth / 2, arrowY);
    
    // Continue bottom edge
    path.lineTo(cornerRadius, arrowY);
    path.arcToPoint(
      Offset(0, arrowY - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Left edge
    path.lineTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );
    
    path.close();

    // Draw shadow (offset slightly)
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main balloon
    canvas.drawPath(path, paint);
    
    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
