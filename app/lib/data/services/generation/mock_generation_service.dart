import 'package:uuid/uuid.dart';
import '../../models/clothing_item.dart';
import '../../models/generation_batch.dart';
import '../../models/outfit.dart';
import '../../repositories/outfit_repository.dart';
import '../../repositories/wardrobe_repository.dart';
import 'generation_service.dart';

/// Mock generation service for the local environment.
/// Generates 4 rule-based outfits directly from the in-memory wardrobe
/// and writes them to the local outfit repository.
class MockGenerationService implements GenerationService {
  MockGenerationService({
    required this.outfitRepository,
    required this.wardrobeRepository,
  });

  final OutfitRepository outfitRepository;
  final WardrobeRepository wardrobeRepository;

  final _uuid = const Uuid();

  @override
  Future<String> triggerGeneration({
    required String userId,
    required String mood,
  }) async {
    final batchId = _uuid.v4();
    final moodEnum = Mood.values.byName(mood);
    final items = await wardrobeRepository.getItems(userId);

    final tops = items.where((i) => i.coverage == CoverageType.top).toList();
    final bottoms =
        items.where((i) => i.coverage == CoverageType.bottom).toList();
    final fullbodies =
        items.where((i) => i.coverage == CoverageType.fullbody).toList();
    final layers =
        items.where((i) => i.coverage == CoverageType.layer).toList();

    final outfits = <Outfit>[];
    var outfitIndex = 0;

    void tryAdd(List<String> ids) {
      if (outfits.length >= 4) return;
      outfits.add(Outfit(
        id: _uuid.v4(),
        itemIds: ids,
        mood: moodEnum,
        createdAt: DateTime.now(),
        batchId: batchId,
      ));
    }

    // Prefer fullbody combos first, then top+bottom
    for (final fb in fullbodies) {
      if (outfits.length >= 2) break;
      final layerIds = layers.isNotEmpty ? [layers[outfitIndex % layers.length].id] : <String>[];
      tryAdd([fb.id, ...layerIds]);
      outfitIndex++;
    }

    for (var i = 0; i < tops.length && outfits.length < 4; i++) {
      if (bottoms.isEmpty) break;
      final bottom = bottoms[i % bottoms.length];
      final layerIds = layers.isNotEmpty ? [layers[i % layers.length].id] : <String>[];
      tryAdd([tops[i].id, bottom.id, ...layerIds]);
    }

    final outfitIds = <String>[];
    for (final outfit in outfits) {
      await outfitRepository.addOutfit(userId, outfit);
      outfitIds.add(outfit.id);
    }

    final batch = GenerationBatch(
      id: batchId,
      mood: moodEnum,
      status: GenerationStatus.complete,
      outfitIds: outfitIds,
      createdAt: DateTime.now(),
    );
    await outfitRepository.addBatch(userId, batch);

    return batchId;
  }
}
