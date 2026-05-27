import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clothing_item.dart';
import '../wardrobe_repository.dart';
import '../../../core/constants/app_constants.dart';

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
    return _collection(userId).snapshots().map(
          (snap) => snap.docs
              .map((d) => ClothingItem.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<List<ClothingItem>> getItems(String userId) async {
    final snap = await _collection(userId).get();
    return snap.docs
        .map((d) => ClothingItem.fromJson({...d.data(), 'id': d.id}))
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
}
