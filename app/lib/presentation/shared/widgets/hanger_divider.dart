import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// The Hanger — a signature editorial divider component.
/// Renders a thin hairline + checkroom icon.
class HangerDivider extends StatelessWidget {
  const HangerDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.outlineVariant],
                stops: [0.0, 0.8],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.checkroom_outlined,
                color: AppTheme.outlineVariant,
                size: 20,
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.outline,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.outlineVariant, Colors.transparent],
                stops: [0.2, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
