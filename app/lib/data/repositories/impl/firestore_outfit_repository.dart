import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/outfit.dart';
import '../../models/generation_batch.dart';
import '../outfit_repository.dart';
import '../../../core/constants/app_constants.dart';

/// Converts a Firestore field that may be a [Timestamp], a [String], or null
/// into an ISO-8601 [String] safe to pass to [DateTime.parse].
String _toIso(dynamic value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is String && value.isNotEmpty) return value;
  return DateTime.now().toIso8601String();
}

Map<String, dynamic> _normalizeOutfit(Map<String, dynamic> data) => {
      ...data,
      'createdAt': _toIso(data['createdAt']),
    };

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
          .map((d) => Outfit.fromJson(_normalizeOutfit({...d.data(), 'id': d.id})))
          .toList());

  @override
  Stream<List<Outfit>> watchBatchOutfits(String userId, String batchId) {
    debugPrint('[repo] watchBatchOutfits userId=$userId batchId=$batchId');
    return _outfits(userId)
        .where('batchId', isEqualTo: batchId)
        .snapshots()
        .map((s) {
      debugPrint('[repo] watchBatchOutfits snapshot count=${s.docs.length}');
      return s.docs
          .map((d) => Outfit.fromJson(_normalizeOutfit({...d.data(), 'id': d.id})))
          .toList();
    }).handleError((Object err, StackTrace st) {
      debugPrint('[repo] watchBatchOutfits stream error: $err\n$st');
    });
  }

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
        .map((d) => Outfit.fromJson(_normalizeOutfit({...d.data(), 'id': d.id})))
        .toList();
  }

  @override
  Future<List<GenerationBatch>> getHistory(String userId) async {
    final snap = await _history(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => GenerationBatch.fromJson(
            {...d.data(), 'id': d.id, 'createdAt': _toIso(d.data()['createdAt'])}))
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
