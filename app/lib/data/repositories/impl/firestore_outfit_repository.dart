import 'package:cloud_firestore/cloud_firestore.dart';
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
  Stream<GenerationBatch> watchBatch(String userId, String batchId) =>
      _history(userId).doc(batchId).snapshots().where((s) => s.exists).map(
            (s) => GenerationBatch.fromJson({...s.data()!, 'id': s.id}),
          );

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
