import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'storage_service.dart';

class FirebaseStorageService implements StorageService {
  FirebaseStorageService(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> uploadClothingPhoto({
    required String userId,
    required String itemId,
    required File file,
  }) async {
    final ref = _storage.ref('users/$userId/wardrobe/$itemId.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  @override
  Future<void> deleteClothingPhoto(String photoUrl) async {
    try {
      await _storage.refFromURL(photoUrl).delete();
    } on FirebaseException catch (e) {
      // Ignore not-found errors — item may have already been deleted.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
