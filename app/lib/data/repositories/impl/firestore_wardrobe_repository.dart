import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clothing_item.dart';
import '../../models/capture_item.dart';
import '../wardrobe_repository.dart';
import '../../../core/constants/app_constants.dart';

String _toIso(dynamic value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is String && value.isNotEmpty) return value;
  return DateTime.now().toIso8601String();
}

Map<String, dynamic> _normalize(Map<String, dynamic> data) => {
      ...data,
      'createdAt': _toIso(data['createdAt']),
    };

class FirestoreWardrobeRepository implements WardrobeRepository {
  FirestoreWardrobeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.wardrobeCollection);

  @override
  Stream<List<ClothingItem>> watchItems(String userId) {
    return _collection(userId)
        .where('pendingReview', isNotEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) =>
                  ClothingItem.fromJson(_normalize({...d.data(), 'id': d.id})))
              .toList(),
        );
  }

  @override
  Future<List<ClothingItem>> getItems(String userId) async {
    final snap = await _collection(userId)
        .where('pendingReview', isNotEqualTo: true)
        .get();
    return snap.docs
        .map((d) =>
            ClothingItem.fromJson(_normalize({...d.data(), 'id': d.id})))
        .toList();
  }

  @override
  Future<void> addItem(String userId, ClothingItem item) =>
      _collection(userId).doc(item.id).set(item.toJson());

  @override
  Future<void> updateItem(String userId, ClothingItem item) =>
      _collection(userId).doc(item.id).set(item.toJson());

  @override
  Future<void> deleteItem(String userId, String itemId) =>
      _collection(userId).doc(itemId).delete();

  // --- Mass capture ---

  @override
  Future<void> createCaptureItem(String userId, CaptureItem item) =>
      _collection(userId).doc(item.id).set(item.toFirestore());

  @override
  Future<void> updateCaptureItem(String userId, CaptureItem item) =>
      _collection(userId).doc(item.id).update(item.toFirestore());

  @override
  Stream<List<CaptureItem>> watchCaptureSession(
      String userId, String sessionId) {
    return _collection(userId)
        .where('captureSessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CaptureItem.fromFirestore({...d.data()}, d.id))
            .toList());
  }

  @override
  Future<void> confirmCaptureSession(
      String userId, List<CaptureItem> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final ref = _collection(userId).doc(item.id);
      batch.update(ref, {
        'pendingReview': false,
        'status': CaptureStatus.confirmed.value,
        if (item.type != null) 'type': item.type!.name,
        if (item.colorHex != null) 'colorHex': item.colorHex,
        if (item.pattern != null) 'pattern': item.pattern!.name,
        if (item.name != null) 'name': item.name,
      });
    }
    await batch.commit();
  }
}
