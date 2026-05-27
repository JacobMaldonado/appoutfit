import 'dart:io';

abstract class StorageService {
  /// Uploads a clothing item photo and returns the public download URL.
  Future<String> uploadClothingPhoto({
    required String userId,
    required String itemId,
    required File file,
  });

  /// Deletes a clothing item photo by its URL.
  Future<void> deleteClothingPhoto(String photoUrl);
}
