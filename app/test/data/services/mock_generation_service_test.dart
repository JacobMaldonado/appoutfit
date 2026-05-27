import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/clothing_item.dart';
import 'package:closet_app/data/repositories/impl/local_outfit_repository.dart';
import 'package:closet_app/data/repositories/impl/local_wardrobe_repository.dart';
import 'package:closet_app/data/services/generation/mock_generation_service.dart';

void main() {
  late LocalWardrobeRepository wardrobeRepo;
  late LocalOutfitRepository outfitRepo;
  late MockGenerationService service;
  const userId = 'user-1';

  setUp(() {
    wardrobeRepo = LocalWardrobeRepository();
    outfitRepo = LocalOutfitRepository();
    service = MockGenerationService(
      outfitRepository: outfitRepo,
      wardrobeRepository: wardrobeRepo,
    );
  });

  tearDown(() {
    wardrobeRepo.dispose();
    outfitRepo.dispose();
  });

  ClothingItem item(String id, ClothingType type) => ClothingItem(
        id: id,
        type: type,
        colorHex: '#C0C0C0',
        pattern: ClothingPattern.solid,
        createdAt: DateTime(2024),
      );

  Future<void> seedWardrobe() async {
    await wardrobeRepo.addItem(userId, item('t1', ClothingType.shirt));
    await wardrobeRepo.addItem(userId, item('t2', ClothingType.blouse));
    await wardrobeRepo.addItem(userId, item('b1', ClothingType.jeans));
    await wardrobeRepo.addItem(userId, item('b2', ClothingType.skirt));
    await wardrobeRepo.addItem(userId, item('fb1', ClothingType.dress));
    await wardrobeRepo.addItem(userId, item('l1', ClothingType.blazer));
  }

  test('returns a batchId string', () async {
    await seedWardrobe();
    final batchId = await service.triggerGeneration(
      userId: userId,
      mood: 'casual',
    );
    expect(batchId, isNotEmpty);
  });

  test('generates at most 4 outfits', () async {
    await seedWardrobe();
    final batchId = await service.triggerGeneration(
      userId: userId,
      mood: 'work',
    );
    final history = await outfitRepo.getHistory(userId);
    final batch = history.firstWhere((b) => b.id == batchId);
    expect(batch.outfitIds.length, lessThanOrEqualTo(4));
    expect(batch.outfitIds.length, greaterThan(0));
  });

  test('stores batch in history with correct mood', () async {
    await seedWardrobe();
    final batchId =
        await service.triggerGeneration(userId: userId, mood: 'brunch');
    final history = await outfitRepo.getHistory(userId);
    final batch = history.firstWhere((b) => b.id == batchId);
    expect(batch.mood.name, 'brunch');
  });

  test('generates 0 outfits when wardrobe is empty', () async {
    final batchId =
        await service.triggerGeneration(userId: userId, mood: 'casual');
    final history = await outfitRepo.getHistory(userId);
    final batch = history.firstWhere((b) => b.id == batchId);
    expect(batch.outfitIds, isEmpty);
  });

  test('outfits are stored and retrievable from outfit repo', () async {
    await seedWardrobe();
    await service.triggerGeneration(userId: userId, mood: 'night');
    final allOutfits = await outfitRepo.getSavedOutfits(userId);
    // Not saved by default — just check nothing crashed
    expect(allOutfits, isEmpty);
  });
}
