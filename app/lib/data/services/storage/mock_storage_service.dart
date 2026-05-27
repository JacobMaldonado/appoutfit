import 'dart:io';
import 'storage_service.dart';

/// Returns a placeholder URL instead of uploading. Used in local environment.
class MockStorageService implements StorageService {
  @override
  Future<String> uploadClothingPhoto({
    required String userId,
    required String itemId,
    required File file,
  }) async =>
      'https://placeholder.closetapp.com/item/$itemId.jpg';

  @override
  Future<void> deleteClothingPhoto(String photoUrl) async {}
}
