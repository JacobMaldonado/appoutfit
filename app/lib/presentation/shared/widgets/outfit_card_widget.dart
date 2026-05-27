import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/outfit.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    required this.colorSwatches,
    this.onSave,
    this.isSaved = false,
  });

  final Outfit outfit;
  final List<Color> colorSwatches;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: _OutfitPreview(colors: colorSwatches),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    outfit.mood.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onSave != null)
                  GestureDetector(
                    onTap: onSave,
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isSaved ? AppTheme.dustyRose : AppTheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitPreview extends StatelessWidget {
  const _OutfitPreview({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) {
      return Container(color: AppTheme.champagne);
    }
    return Row(
      children: [
        for (final color in colors.take(4))
          Expanded(child: Container(color: color)),
      ],
    );
  }
}
