import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:closet_app/config/app_config.dart';
import 'package:closet_app/core/notifiers/mass_capture_notifier.dart';
import 'package:closet_app/data/models/capture_item.dart';
import 'package:closet_app/data/models/clothing_item.dart';
import 'package:closet_app/data/repositories/wardrobe_repository.dart';
import 'package:closet_app/data/services/auth/mock_auth_service.dart';
import 'package:closet_app/data/services/classification/clothing_classification_service.dart';
import 'package:closet_app/data/services/storage/storage_service.dart';

// ─── Stubs ────────────────────────────────────────────────────────────────────

class _StubStorage implements StorageService {
  final List<String> uploaded = [];
  String? failNext;

  @override
  Future<String> uploadClothingPhoto({
    required String userId,
    required String itemId,
    required File file,
  }) async {
    if (failNext != null) {
      final e = failNext!;
      failNext = null;
      throw Exception(e);
    }
    final url = 'https://storage.test/$userId/$itemId.jpg';
    uploaded.add(url);
    return url;
  }

  @override
  Future<void> deleteClothingPhoto(String photoUrl) async {}
}

class _StubWardrobe implements WardrobeRepository {
  final List<CaptureItem> captureItems = [];
  final List<CaptureItem> confirmedItems = [];

  @override
  Future<void> createCaptureItem(String userId, CaptureItem item) async {
    captureItems.add(item);
  }

  @override
  Future<void> updateCaptureItem(String userId, CaptureItem item) async {
    final i = captureItems.indexWhere((c) => c.id == item.id);
    if (i >= 0) captureItems[i] = item;
  }

  @override
  Stream<List<CaptureItem>> watchCaptureSession(String userId, String sessionId) {
    return Stream.value(
        captureItems.where((c) => c.captureSessionId == sessionId).toList());
  }

  @override
  Future<void> confirmCaptureSession(String userId, List<CaptureItem> items) async {
    confirmedItems.addAll(items);
  }

  @override
  Future<void> addItem(String userId, ClothingItem item) async {}
  @override
  Future<void> updateItem(String userId, ClothingItem item) async {}
  @override
  Future<void> deleteItem(String userId, String itemId) async {}
  @override
  Future<List<ClothingItem>> getItems(String userId) async => [];
  @override
  Stream<List<ClothingItem>> watchItems(String userId) => Stream.value([]);
  void dispose() {}
}

class _StubConfig implements AppConfig {
  @override
  String get env => 'test';
  @override
  bool get useFirebase => false;
  @override
  String get generationApiBaseUrl => 'http://localhost';
}

/// Extends the concrete class and overrides classifyItem — no real HTTP calls.
class _StubClassifier extends ClothingClassificationService {
  _StubClassifier()
      : super(
          config: _StubConfig(),
          httpClient: http.Client(),
          authService: MockAuthService(),
        );

  final List<String> classified = [];
  bool shouldFail = false;

  @override
  Future<void> classifyItem({
    required String userId,
    required String itemId,
    required String imageUrl,
  }) async {
    if (shouldFail) throw Exception('classification failed');
    classified.add(itemId);
  }
}

class _ThrowingWardrobe extends _StubWardrobe {
  @override
  Future<void> confirmCaptureSession(String userId, List<CaptureItem> items) async {
    throw Exception('Firestore failure');
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

File _fakeTempFile(String name) {
  final f = File('${Directory.systemTemp.path}/$name.jpg');
  f.createSync();
  return f;
}

MassCaptureNotifier _makeNotifier({
  _StubStorage? storage,
  _StubWardrobe? wardrobe,
  _StubClassifier? classifier,
}) =>
    MassCaptureNotifier(
      wardrobeRepo: wardrobe ?? _StubWardrobe(),
      storageService: storage ?? _StubStorage(),
      classificationService: classifier ?? _StubClassifier(),
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('MassCaptureNotifier.startSession', () {
    test('initialises a new sessionId and resets counters', () {
      final notifier = _makeNotifier();
      expect(notifier.captureSessionId, isNull);
      expect(notifier.capturedCount, 0);

      notifier.startSession();

      expect(notifier.captureSessionId, isNotNull);
      expect(notifier.capturedCount, 0);
      expect(notifier.thumbnails, isEmpty);
    });

    test('calling startSession twice generates a different sessionId', () {
      final notifier = _makeNotifier();
      notifier.startSession();
      final first = notifier.captureSessionId;

      notifier.startSession();
      final second = notifier.captureSessionId;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, isNot(equals(second)));
    });
  });

  group('MassCaptureNotifier.captureItem', () {
    test('increments count, adds thumbnail, uploads, creates doc', () async {
      final storage = _StubStorage();
      final wardrobe = _StubWardrobe();
      final classifier = _StubClassifier();
      final notifier =
          _makeNotifier(storage: storage, wardrobe: wardrobe, classifier: classifier);

      notifier.startSession();
      final file = _fakeTempFile('test_capture_1');

      await notifier.captureItem(
        userId: 'u1',
        imageFile: file,
        backgroundRemovedFile: (f) => f,
      );

      expect(notifier.capturedCount, 1);
      expect(notifier.thumbnails, hasLength(1));
      expect(storage.uploaded, hasLength(1));
      expect(wardrobe.captureItems, hasLength(1));
      expect(classifier.classified, hasLength(1));

      file.deleteSync();
    });

    test('auto-starts session if not already started', () async {
      final notifier = _makeNotifier();
      expect(notifier.captureSessionId, isNull);

      final file = _fakeTempFile('test_capture_auto');
      await notifier.captureItem(
        userId: 'u1',
        imageFile: file,
        backgroundRemovedFile: (f) => f,
      );

      expect(notifier.captureSessionId, isNotNull);
      expect(notifier.capturedCount, 1);

      file.deleteSync();
    });

    test('multiple captures share same sessionId', () async {
      final wardrobe = _StubWardrobe();
      final notifier = _makeNotifier(wardrobe: wardrobe);
      notifier.startSession();
      final sessionId = notifier.captureSessionId!;

      final f1 = _fakeTempFile('cap_multi_1');
      final f2 = _fakeTempFile('cap_multi_2');

      await notifier.captureItem(
          userId: 'u1', imageFile: f1, backgroundRemovedFile: (f) => f);
      await notifier.captureItem(
          userId: 'u1', imageFile: f2, backgroundRemovedFile: (f) => f);

      expect(notifier.capturedCount, 2);
      for (final item in wardrobe.captureItems) {
        expect(item.captureSessionId, sessionId);
      }

      f1.deleteSync();
      f2.deleteSync();
    });

    test('storage failure decrements count and removes thumbnail', () async {
      final storage = _StubStorage()..failNext = 'upload error';
      final notifier = _makeNotifier(storage: storage);
      notifier.startSession();

      final file = _fakeTempFile('test_capture_fail');
      await notifier.captureItem(
        userId: 'u1',
        imageFile: file,
        backgroundRemovedFile: (f) => f,
      );

      expect(notifier.capturedCount, 0);
      expect(notifier.thumbnails, isEmpty);
      expect(notifier.error, isNotNull);

      file.deleteSync();
    });
  });

  group('MassCaptureNotifier.confirmSession', () {
    test('delegates to wardrobeRepo.confirmCaptureSession', () async {
      final wardrobe = _StubWardrobe();
      final notifier = _makeNotifier(wardrobe: wardrobe);
      notifier.startSession();

      final item = CaptureItem(
        id: 'item-1',
        captureSessionId: notifier.captureSessionId!,
        createdAt: DateTime.now(),
        status: CaptureStatus.ready,
      );

      await notifier.confirmSession(userId: 'u1', items: [item]);

      expect(wardrobe.confirmedItems, hasLength(1));
      expect(wardrobe.confirmedItems.first.id, 'item-1');
    });

    test('rethrows on repo failure', () {
      final n = MassCaptureNotifier(
        wardrobeRepo: _ThrowingWardrobe(),
        storageService: _StubStorage(),
        classificationService: _StubClassifier(),
      );
      n.startSession();

      expect(
        () => n.confirmSession(userId: 'u1', items: []),
        throwsException,
      );
    });
  });

  group('MassCaptureNotifier.clearSession', () {
    test('resets all state', () async {
      final notifier = _makeNotifier();
      notifier.startSession();

      final file = _fakeTempFile('test_clear');
      await notifier.captureItem(
        userId: 'u1',
        imageFile: file,
        backgroundRemovedFile: (f) => f,
      );

      expect(notifier.capturedCount, 1);
      notifier.clearSession();

      expect(notifier.captureSessionId, isNull);
      expect(notifier.capturedCount, 0);
      expect(notifier.thumbnails, isEmpty);

      file.deleteSync();
    });
  });
}
