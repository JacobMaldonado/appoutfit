import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/clothing_item.dart';
import 'package:closet_app/data/repositories/impl/local_wardrobe_repository.dart';

void main() {
  late LocalWardrobeRepository repo;
  const userId = 'user-1';

  setUp(() => repo = LocalWardrobeRepository());
  tearDown(() => repo.dispose());

  ClothingItem makeItem(String id, ClothingType type) => ClothingItem(
        id: id,
        type: type,
        colorHex: '#FFFFFF',
        pattern: ClothingPattern.solid,
        createdAt: DateTime(2024),
      );

  test('getItems returns empty list initially', () async {
    final items = await repo.getItems(userId);
    expect(items, isEmpty);
  });

  test('addItem stores item and getItems reflects it', () async {
    final item = makeItem('item-1', ClothingType.shirt);
    await repo.addItem(userId, item);
    final items = await repo.getItems(userId);
    expect(items, contains(item));
    expect(items.length, 1);
  });

  test('updateItem replaces matching item', () async {
    final item = makeItem('item-1', ClothingType.shirt);
    await repo.addItem(userId, item);

    final updated = ClothingItem(
      id: 'item-1',
      type: ClothingType.blouse,
      colorHex: '#000000',
      pattern: ClothingPattern.striped,
      createdAt: DateTime(2024),
    );
    await repo.updateItem(userId, updated);
    final items = await repo.getItems(userId);
    expect(items.length, 1);
    expect(items.first.type, ClothingType.blouse);
  });

  test('deleteItem removes item by id', () async {
    await repo.addItem(userId, makeItem('item-1', ClothingType.jeans));
    await repo.addItem(userId, makeItem('item-2', ClothingType.dress));
    await repo.deleteItem(userId, 'item-1');

    final items = await repo.getItems(userId);
    expect(items.length, 1);
    expect(items.first.id, 'item-2');
  });

  test('watchItems stream emits on addItem', () async {
    final stream = repo.watchItems(userId);
    final future = stream.first;
    await repo.addItem(userId, makeItem('item-1', ClothingType.coat));
    final emitted = await future;
    expect(emitted.length, 1);
  });

  test('different users have isolated stores', () async {
    await repo.addItem(userId, makeItem('item-1', ClothingType.skirt));
    final otherItems = await repo.getItems('user-2');
    expect(otherItems, isEmpty);
  });
}
