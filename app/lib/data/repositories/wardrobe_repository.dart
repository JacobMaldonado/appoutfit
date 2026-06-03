import '../models/clothing_item.dart';
import '../models/capture_item.dart';

abstract class WardrobeRepository {
  Stream<List<ClothingItem>> watchItems(String userId);
  Future<List<ClothingItem>> getItems(String userId);
  Future<void> addItem(String userId, ClothingItem item);
  Future<void> updateItem(String userId, ClothingItem item);
  Future<void> deleteItem(String userId, String itemId);

  // Mass capture
  Future<void> createCaptureItem(String userId, CaptureItem item);
  Future<void> updateCaptureItem(String userId, CaptureItem item);
  Stream<List<CaptureItem>> watchCaptureSession(String userId, String sessionId);
  Future<void> confirmCaptureSession(String userId, List<CaptureItem> items);
}
