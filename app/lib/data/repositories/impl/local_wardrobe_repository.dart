import 'dart:async';
import '../../models/clothing_item.dart';
import '../../models/capture_item.dart';
import '../wardrobe_repository.dart';

/// In-memory wardrobe repository for the local (mock) environment.
class LocalWardrobeRepository implements WardrobeRepository {
  final Map<String, List<ClothingItem>> _store = {};
  final Map<String, StreamController<List<ClothingItem>>> _controllers = {};

  @override
  Stream<List<ClothingItem>> watchItems(String userId) {
    _controllers[userId] ??=
        StreamController<List<ClothingItem>>.broadcast();
    return _controllers[userId]!.stream;
  }

  @override
  Future<List<ClothingItem>> getItems(String userId) async {
    return List.unmodifiable(_store[userId] ?? []);
  }

  @override
  Future<void> addItem(String userId, ClothingItem item) async {
    _store[userId] = [...(_store[userId] ?? []), item];
    _emit(userId);
  }

  @override
  Future<void> updateItem(String userId, ClothingItem item) async {
    final items = _store[userId] ?? [];
    _store[userId] = [
      for (final i in items)
        if (i.id == item.id) item else i,
    ];
    _emit(userId);
  }

  @override
  Future<void> deleteItem(String userId, String itemId) async {
    _store[userId] =
        (_store[userId] ?? []).where((i) => i.id != itemId).toList();
    _emit(userId);
  }

  // --- Mass capture (no-op stubs for local env) ---

  @override
  Future<void> createCaptureItem(String userId, CaptureItem item) async {}

  @override
  Future<void> updateCaptureItem(String userId, CaptureItem item) async {}

  @override
  Stream<List<CaptureItem>> watchCaptureSession(
          String userId, String sessionId) =>
      Stream.value([]);

  @override
  Future<void> confirmCaptureSession(
      String userId, List<CaptureItem> items) async {}

  void _emit(String userId) {
    _controllers[userId]?.add(List.unmodifiable(_store[userId] ?? []));
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}
