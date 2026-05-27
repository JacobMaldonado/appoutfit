import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/outfit.dart';

class MoodChip extends StatelessWidget {
  const MoodChip({
    super.key,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.dustyRose : AppTheme.champagne,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.dustyRose.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              mood.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primary : AppTheme.outline,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
