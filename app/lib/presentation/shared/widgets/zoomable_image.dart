import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A network image with a "Tap to zoom" badge overlay.
/// Tapping opens a full-screen dark modal with pinch-to-zoom.
class ZoomableNetworkImage extends StatelessWidget {
  const ZoomableNetworkImage({
    super.key,
    required this.url,
    this.height = 320,
    this.borderRadius = 24,
    this.fallback,
  });

  final String url;
  final double height;
  final double borderRadius;

  /// Widget shown when image fails or is absent.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: GestureDetector(
          onTap: () => _openZoom(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppTheme.champagne,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (ctx, err, stack) =>
                    fallback ??
                    Container(
                      color: AppTheme.champagne,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: AppTheme.outlineVariant,
                        ),
                      ),
                    ),
              ),
              // Bottom gradient strip + zoom badge
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.zoom_in, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openZoom(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _ZoomDialog(url: url),
    );
  }
}

class _ZoomDialog extends StatelessWidget {
  const _ZoomDialog({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 6,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Pinch to zoom · Tap anywhere to close',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
