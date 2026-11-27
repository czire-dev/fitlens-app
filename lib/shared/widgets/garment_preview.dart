import 'package:flutter/material.dart';

enum GarmentView {
  front('Front'),
  back('Back');

  const GarmentView(this.label);

  final String label;
}

class GarmentPreview extends StatelessWidget {
  const GarmentPreview({
    super.key,
    required this.view,
    required this.artHeight,
  });

  final GarmentView view;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          colors: [colors.surfaceContainerLow, colors.surfaceContainerHigh],
          radius: 0.9,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: artHeight,
              child: CustomPaint(
                painter: _TeeIllustration(
                  view: view,
                  shirtColor: colors.onSurface,
                  inkColor: colors.secondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${view.label} placeholder',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeeIllustration extends CustomPainter {
  const _TeeIllustration({
    required this.view,
    required this.shirtColor,
    required this.inkColor,
  });

  final GarmentView view;
  final Color shirtColor;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Use the same drawing coordinates for thumbnails and the detail gallery.
    final scale = size.width / 240 < size.height / 196
        ? size.width / 240
        : size.height / 196;
    canvas.translate(
      (size.width - 240 * scale) / 2,
      (size.height - 196 * scale) / 2,
    );
    canvas.scale(scale);

    final back = view == GarmentView.back;
    final silhouette = Path()
      ..moveTo(91, 10)
      ..quadraticBezierTo(120, back ? 23 : 55, 149, 10)
      ..lineTo(179, 21)
      ..quadraticBezierTo(200, 36, 226, 69)
      ..lineTo(192, 95)
      ..lineTo(173, 79)
      ..lineTo(177, 179)
      ..quadraticBezierTo(120, 186, 63, 179)
      ..lineTo(67, 79)
      ..lineTo(48, 95)
      ..lineTo(14, 69)
      ..quadraticBezierTo(40, 36, 61, 21)
      ..close();
    canvas.drawShadow(silhouette, shirtColor.withValues(alpha: 0.75), 8, false);
    canvas.drawPath(silhouette, Paint()..color = shirtColor);

    final seam = Paint()
      ..color = const Color(0xFF615950)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final stitching = Path()
      ..moveTo(91, 15)
      ..quadraticBezierTo(120, back ? 30 : 62, 149, 15)
      ..moveTo(63, 25)
      ..quadraticBezierTo(72, 47, 67, 79)
      ..moveTo(177, 25)
      ..quadraticBezierTo(168, 47, 173, 79)
      ..moveTo(68, 173)
      ..quadraticBezierTo(120, 178, 172, 173);
    canvas.drawPath(stitching, seam);

    final graphic = TextPainter(
      text: TextSpan(
        text: 'SEVN',
        style: TextStyle(
          color: inkColor,
          fontSize: back ? 29 : 11,
          fontWeight: FontWeight.w900,
          letterSpacing: back ? 3 : 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final graphicY = back ? 65.0 : 59.0;
    final graphicX = (back ? 120.0 : 143.0) - graphic.width / 2;
    graphic.paint(canvas, Offset(graphicX, graphicY));
    canvas.drawLine(
      Offset(graphicX, graphicY + graphic.height + 2),
      Offset(graphicX + graphic.width, graphicY + graphic.height + 2),
      Paint()..color = inkColor,
    );
    graphic.dispose();
  }

  @override
  bool shouldRepaint(_TeeIllustration oldDelegate) =>
      view != oldDelegate.view ||
      shirtColor != oldDelegate.shirtColor ||
      inkColor != oldDelegate.inkColor;
}
