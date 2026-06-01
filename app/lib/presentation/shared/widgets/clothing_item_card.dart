import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/clothing_item.dart';

/// Card displaying a single clothing item with its SVG-like color swatch.
class ClothingItemCard extends StatelessWidget {
  const ClothingItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ClothingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(item.colorHex);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF36454F).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: item.photoUrl != null
                    ? Image.network(
                        item.photoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : _ColorSwatch(color: color, pattern: item.pattern),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.pattern.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.pattern});

  final Color color;
  final ClothingPattern pattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: pattern == ClothingPattern.solid
          ? null
          : CustomPaint(
              painter: _PatternPainter(pattern: pattern, color: color),
            ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.pattern, required this.color});

  final ClothingPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.computeLuminance() > 0.5
          ? Colors.black.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case ClothingPattern.striped:
        for (double i = -size.height; i < size.width + size.height; i += 12) {
          canvas.drawLine(
            Offset(i, 0),
            Offset(i + size.height, size.height),
            paint,
          );
        }
      case ClothingPattern.plaid:
        for (double i = 0; i < size.width; i += 16) {
          canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
        }
        for (double i = 0; i < size.height; i += 16) {
          canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
        }
      case ClothingPattern.floral:
        final dotPaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        for (double x = 8; x < size.width; x += 20) {
          for (double y = 8; y < size.height; y += 20) {
            canvas.drawCircle(Offset(x, y), 3, dotPaint);
          }
        }
      case ClothingPattern.printed:
        for (double x = 10; x < size.width; x += 24) {
          for (double y = 10; y < size.height; y += 24) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(x, y),
                  width: 10,
                  height: 10,
                ),
                const Radius.circular(3),
              ),
              paint,
            );
          }
        }
      case ClothingPattern.solid:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
