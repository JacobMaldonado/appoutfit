import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/capture_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/services/classification/clothing_classification_service.dart';
import '../../data/services/storage/storage_service.dart';

/// Manages the state of a mass-capture session.
///
/// Lifecycle:
///   1. [startSession] — generates a new session ID, resets counters.
///   2. [captureItem] — called for each photo taken in [MassCameraScreen].
///      Runs background removal → upload → Firestore doc → metadata API call
///      in parallel; the caller is unblocked immediately after upload.
///   3. [confirmSession] — marks all reviewed items as confirmed in Firestore.
///   4. [clearSession] — called when navigating away after confirmation.
class MassCaptureNotifier extends ChangeNotifier {
  MassCaptureNotifier({
    required this.wardrobeRepo,
    required this.storageService,
    required this.classificationService,
  });

  final WardrobeRepository wardrobeRepo;
  final StorageService storageService;
  final ClothingClassificationService classificationService;

  String? _captureSessionId;
  int _capturedCount = 0;
  int _processingCount = 0;
  final List<File> _thumbnails = [];
  String? _error;

  String? get captureSessionId => _captureSessionId;
  int get capturedCount => _capturedCount;
  bool get isProcessing => _processingCount > 0;
  List<File> get thumbnails => List.unmodifiable(_thumbnails);
  String? get error => _error;

  void startSession() {
    _captureSessionId = const Uuid().v4();
    _capturedCount = 0;
    _processingCount = 0;
    _thumbnails.clear();
    _error = null;
    notifyListeners();
  }

  /// Processes a captured photo file through the full pipeline.
  ///
  /// Returns immediately after creating the Firestore doc. The classification
  /// result arrives via Firestore realtime stream in [MassReviewScreen].
  Future<void> captureItem({
    required String userId,
    required File imageFile,
    required File Function(File) backgroundRemovedFile,
  }) async {
    if (_captureSessionId == null) startSession();

    final itemId = const Uuid().v4();
    _processingCount++;
    _thumbnails.add(imageFile);
    _capturedCount++;
    _error = null;
    notifyListeners();

    try {
      final bgRemovedFile = backgroundRemovedFile(imageFile);

      // Upload to Storage
      final photoUrl = await storageService.uploadClothingPhoto(
        userId: userId,
        itemId: itemId,
        file: bgRemovedFile,
      );

      // Create pending Firestore document
      final captureItem = CaptureItem(
        id: itemId,
        captureSessionId: _captureSessionId!,
        createdAt: DateTime.now(),
        photoUrl: photoUrl,
        status: CaptureStatus.classifying,
      );
      await wardrobeRepo.createCaptureItem(userId, captureItem);

      // Trigger classification (result arrives via Firestore stream)
      await classificationService.classifyItem(
        userId: userId,
        itemId: itemId,
        imageUrl: photoUrl,
      );
    } catch (e) {
      debugPrint('[MassCapture] captureItem error: $e');
      _error = 'Failed to process one photo — tap to retry or skip.';
      _capturedCount--;
      _thumbnails.removeLast();
    } finally {
      _processingCount--;
      notifyListeners();
    }
  }

  Future<void> confirmSession({
    required String userId,
    required List<CaptureItem> items,
  }) async {
    try {
      await wardrobeRepo.confirmCaptureSession(userId, items);
    } catch (e) {
      debugPrint('[MassCapture] confirmSession error: $e');
      _error = 'Failed to save items. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  void clearSession() {
    _captureSessionId = null;
    _capturedCount = 0;
    _processingCount = 0;
    _thumbnails.clear();
    _error = null;
    notifyListeners();
  }
}
