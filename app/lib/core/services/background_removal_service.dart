import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Removes the background from a clothing photo using native platform APIs.
///
/// iOS 17+: VNGenerateForegroundInstanceMaskRequest (Vision framework)
/// Android: ML Kit Subject Segmentation
///
/// On older platforms or if the native call fails, the original file is returned
/// unchanged as a graceful fallback.
class BackgroundRemovalService {
  static const _channel = MethodChannel('closet/background_removal');

  Future<File> removeBackground(File imageFile) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'removeBackground',
        {'imagePath': imageFile.path},
      );
      if (result != null && result.isNotEmpty) {
        return File(result);
      }
    } on PlatformException catch (e) {
      debugPrint('[BackgroundRemoval] platform error: ${e.message}');
    } catch (e) {
      debugPrint('[BackgroundRemoval] error: $e');
    }
    // Graceful fallback: return original image unchanged
    return imageFile;
  }
}
