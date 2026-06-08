import 'package:flutter/material.dart';

enum PaperStyle { blank, ruled, grid, dotted, cream }

extension PaperStyleExtension on PaperStyle {
  String get label {
    switch (this) {
      case PaperStyle.ruled:
        return 'Ruled';
      case PaperStyle.grid:
        return 'Grid';
      case PaperStyle.dotted:
        return 'Dotted';
      case PaperStyle.cream:
        return 'Cream';
      case PaperStyle.blank:
        return 'Blank';
    }
  }

  IconData get icon {
    switch (this) {
      case PaperStyle.ruled:
        return Icons.notes;
      case PaperStyle.grid:
        return Icons.grid_on;
      case PaperStyle.dotted:
        return Icons.blur_on;
      case PaperStyle.cream:
        return Icons.wb_sunny;
      case PaperStyle.blank:
        return Icons.crop_16_9;
    }
  }
}

class CustomShape extends StatelessWidget {
  final Widget child;
  final PaperStyle style;
  final double borderRadius;
  final Color backgroundColor;
  final EdgeInsets padding;

  const CustomShape({
    super.key,
    required this.child,
    this.style = PaperStyle.blank,
    this.borderRadius = 20,
    this.backgroundColor = const Color(0xFFF8F8FF),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapePainter(
        style: style,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final PaperStyle style;
  final Color backgroundColor;
  final double borderRadius;

  _ShapePainter({
    required this.style,
    required this.backgroundColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, paint);

    final border = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, border);

    canvas.clipRRect(rrect);
    final contentRect = Rect.fromLTRB(
      16,
      16,
      size.width - 16,
      size.height - 16,
    );

    switch (style) {
      case PaperStyle.ruled:
        _drawRuled(canvas, contentRect);
        break;
      case PaperStyle.grid:
        _drawGrid(canvas, contentRect);
        break;
      case PaperStyle.dotted:
        _drawDotted(canvas, contentRect);
        break;
      case PaperStyle.cream:
        _drawCream(canvas, contentRect);
        break;
      case PaperStyle.blank:
        break;
    }
  }

  void _drawRuled(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFB9D6EF)
      ..strokeWidth = 1;
    for (var y = rect.top; y < rect.bottom; y += 24) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFB0B7C2)
      ..strokeWidth = 0.8;
    for (var y = rect.top; y < rect.bottom; y += 24) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
    for (var x = rect.left; x < rect.right; x += 24) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }
  }

  void _drawDotted(Canvas canvas, Rect rect) {
    final paint = Paint()..color = const Color(0xFFB0B7C2);
    const spacing = 16.0;
    for (var y = rect.top; y < rect.bottom; y += spacing) {
      for (var x = rect.left; x < rect.right; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  void _drawCream(Canvas canvas, Rect rect) {
    final sky = Paint()..color = const Color(0xFFFFF4DB);
    canvas.drawRect(rect, sky);
    final linePaint = Paint()
      ..color = const Color(0xFFF2E1B8)
      ..strokeWidth = 1;
    for (var y = rect.top + 20; y < rect.bottom; y += 28) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
