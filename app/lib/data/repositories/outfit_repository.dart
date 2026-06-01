import '../models/outfit.dart';
import '../models/generation_batch.dart';

abstract class OutfitRepository {
  Stream<List<Outfit>> watchOutfits(String userId);

  /// Watches outfits that belong to a specific batch, querying by the
  /// [batchId] field stored on each outfit document.
  Stream<List<Outfit>> watchBatchOutfits(String userId, String batchId);

  /// Emits null while the history doc doesn't exist yet (pending), a
  /// [GenerationBatch] once it appears, and errors on permission/network issues.
  Stream<GenerationBatch?> watchBatch(String userId, String batchId);
  Future<List<Outfit>> getSavedOutfits(String userId);
  Future<List<GenerationBatch>> getHistory(String userId);
  Future<void> saveOutfit(String userId, String outfitId, {required bool saved});
  Future<void> addOutfit(String userId, Outfit outfit);
  Future<void> addBatch(String userId, GenerationBatch batch);
}
