import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../auth/auth_service.dart';

/// Calls the backend /v1/metadata endpoint to classify a clothing item.
///
/// The service fetches the image at [imageUrl], runs Gemini vision on it, and
/// writes the extracted metadata back to Firestore under
/// users/{userId}/wardrobe/{itemId}. The client receives the result via a
/// realtime Firestore stream (watchCaptureSession).
class ClothingClassificationService {
  ClothingClassificationService({
    required this.config,
    required this.httpClient,
    required this.authService,
  });

  final AppConfig config;
  final http.Client httpClient;
  final AuthService authService;

  Future<void> classifyItem({
    required String userId,
    required String itemId,
    required String imageUrl,
  }) async {
    final url = Uri.parse(
      '${config.generationApiBaseUrl}${AppConstants.metadataEndpoint}',
    );
    final idToken = await authService.getIdToken();

    final response = await httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'user_id': userId,
        'item_id': itemId,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint(
        '[Classify] metadata API error ${response.statusCode}: ${response.body}',
      );
      throw Exception(
        'Classification API error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
