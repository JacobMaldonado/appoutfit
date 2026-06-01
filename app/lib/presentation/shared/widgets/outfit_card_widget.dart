import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/outfit.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    required this.colorSwatches,
    this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  final Outfit outfit;
  final List<Color> colorSwatches;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: outfit.imageUrl != null
                  ? Image.network(
                      outfit.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppTheme.champagne,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) =>
                          _OutfitPreview(colors: colorSwatches),
                    )
                  : _OutfitPreview(colors: colorSwatches),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        outfit.mood.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (outfit.styleNote != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          outfit.styleNote!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
      ), // Column
    ), // Container
  ); // GestureDetector
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
