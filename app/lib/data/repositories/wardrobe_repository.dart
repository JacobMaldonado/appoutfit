import '../models/clothing_item.dart';

abstract class WardrobeRepository {
  Stream<List<ClothingItem>> watchItems(String userId);
  Future<List<ClothingItem>> getItems(String userId);
  Future<void> addItem(String userId, ClothingItem item);
  Future<void> updateItem(String userId, ClothingItem item);
  Future<void> deleteItem(String userId, String itemId);
}
