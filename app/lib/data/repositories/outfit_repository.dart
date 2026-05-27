import '../models/outfit.dart';
import '../models/generation_batch.dart';

abstract class OutfitRepository {
  Stream<List<Outfit>> watchOutfits(String userId);
  Stream<GenerationBatch> watchBatch(String userId, String batchId);
  Future<List<Outfit>> getSavedOutfits(String userId);
  Future<List<GenerationBatch>> getHistory(String userId);
  Future<void> saveOutfit(String userId, String outfitId, {required bool saved});
  Future<void> addOutfit(String userId, Outfit outfit);
  Future<void> addBatch(String userId, GenerationBatch batch);
}
