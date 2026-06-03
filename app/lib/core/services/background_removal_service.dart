import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_background_remover/image_background_remover.dart';

/// Removes the background from a clothing photo using an offline ONNX model
/// via the `image_background_remover` package.
///
/// Call [removeBg] to process an image. The ONNX session is initialised lazily
/// on the first call and reused for subsequent calls.
///
/// On any failure the original file is returned unchanged as a graceful fallback.
class BackgroundRemovalService {
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await BackgroundRemover.instance.initializeOrt();
    _initialized = true;
  }

  Future<File> removeBackground(File imageFile) async {
    try {
      await _ensureInit();

      final bytes = await imageFile.readAsBytes();
      final ui.Image resultImage =
          await BackgroundRemover.instance.removeBg(bytes);

      final byteData =
          await resultImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return imageFile;

      final outputPath = _bgRemovedPath(imageFile.path);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());
      return outputFile;
    } catch (e) {
      debugPrint('[BackgroundRemoval] error: $e');
      return imageFile;
    }
  }

  Future<void> dispose() => BackgroundRemover.instance.dispose();

  static String _bgRemovedPath(String originalPath) {
    final lastDot = originalPath.lastIndexOf('.');
    final lastSep = originalPath.lastIndexOf('/');
    final base = lastDot > lastSep
        ? originalPath.substring(0, lastDot)
        : originalPath;
    return '${base}_bg_removed.png';
  }
}
