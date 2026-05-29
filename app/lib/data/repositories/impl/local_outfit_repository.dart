import 'dart:async';
import '../../models/outfit.dart';
import '../../models/generation_batch.dart';
import '../outfit_repository.dart';

/// In-memory outfit repository for the local (mock) environment.
class LocalOutfitRepository implements OutfitRepository {
  final Map<String, List<Outfit>> _outfits = {};
  final Map<String, List<GenerationBatch>> _batches = {};
  final Map<String, StreamController<List<Outfit>>> _outfitControllers = {};
  final Map<String, StreamController<GenerationBatch?>> _batchControllers = {};

  @override
  Stream<List<Outfit>> watchOutfits(String userId) {
    _outfitControllers[userId] ??=
        StreamController<List<Outfit>>.broadcast();
    return _outfitControllers[userId]!.stream;
  }

  @override
  Stream<GenerationBatch?> watchBatch(String userId, String batchId) {
    final key = '$userId:$batchId';
    _batchControllers[key] ??=
        StreamController<GenerationBatch?>.broadcast();
    return _batchControllers[key]!.stream;
  }

  @override
  Future<List<Outfit>> getSavedOutfits(String userId) async {
    return (_outfits[userId] ?? []).where((o) => o.saved).toList();
  }

  @override
  Future<List<GenerationBatch>> getHistory(String userId) async {
    return List.unmodifiable(_batches[userId] ?? []);
  }

  @override
  Future<void> saveOutfit(
    String userId,
    String outfitId, {
    required bool saved,
  }) async {
    _outfits[userId] = (_outfits[userId] ?? [])
        .map((o) => o.id == outfitId ? o.copyWith(saved: saved) : o)
        .toList();
    _outfitControllers[userId]?.add(List.unmodifiable(_outfits[userId]!));
  }

  @override
  Future<void> addOutfit(String userId, Outfit outfit) async {
    _outfits[userId] = [...(_outfits[userId] ?? []), outfit];
    _outfitControllers[userId]
        ?.add(List.unmodifiable(_outfits[userId]!));
  }

  @override
  Future<void> addBatch(String userId, GenerationBatch batch) async {
    _batches[userId] = [...(_batches[userId] ?? []), batch];
    final key = '$userId:${batch.id}';
    _batchControllers[key]?.add(batch);
  }

  void dispose() {
    for (final c in _outfitControllers.values) {
      c.close();
    }
    for (final c in _batchControllers.values) {
      c.close();
    }
  }
}
