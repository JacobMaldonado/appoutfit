import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/outfit.dart';
import '../../models/generation_batch.dart';
import '../outfit_repository.dart';
import '../../../core/constants/app_constants.dart';

class FirestoreOutfitRepository implements OutfitRepository {
  FirestoreOutfitRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _outfits(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.outfitsCollection);

  CollectionReference<Map<String, dynamic>> _history(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.historyCollection);

  @override
  Stream<List<Outfit>> watchOutfits(String userId) => _outfits(userId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Outfit.fromJson({...d.data(), 'id': d.id}))
          .toList());

  @override
  Stream<GenerationBatch?> watchBatch(String userId, String batchId) {
    final path = '${AppConstants.usersCollection}/$userId/${AppConstants.historyCollection}/$batchId';
    debugPrint('[repo] watchBatch subscribing to path=$path');
    return _history(userId).doc(batchId).snapshots().map((s) {
      debugPrint(
        '[repo] watchBatch snapshot received: exists=${s.exists} '
        'metadata.isFromCache=${s.metadata.isFromCache} data=${s.data()}',
      );
      if (!s.exists) return null;
      return GenerationBatch.fromJson({...s.data()!, 'id': s.id});
    }).handleError((Object err, StackTrace st) {
      debugPrint('[repo] watchBatch stream error: $err\n$st');
    });
  }

  @override
  Future<List<Outfit>> getSavedOutfits(String userId) async {
    final snap =
        await _outfits(userId).where('saved', isEqualTo: true).get();
    return snap.docs
        .map((d) => Outfit.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<List<GenerationBatch>> getHistory(String userId) async {
    final snap = await _history(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => GenerationBatch.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> saveOutfit(
    String userId,
    String outfitId, {
    required bool saved,
  }) =>
      _outfits(userId).doc(outfitId).update({'saved': saved});

  @override
  Future<void> addOutfit(String userId, Outfit outfit) =>
      _outfits(userId).doc(outfit.id).set(outfit.toJson());

  @override
  Future<void> addBatch(String userId, GenerationBatch batch) =>
      _history(userId).doc(batch.id).set(batch.toJson());
}
