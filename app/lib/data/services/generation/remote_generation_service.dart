import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../auth/auth_service.dart';
import 'generation_service.dart';
import '../../../core/constants/app_constants.dart';

/// Calls the remote generation API and returns the batchId.
/// Results arrive via a Firestore realtime subscription on history/{batchId}.
class RemoteGenerationService implements GenerationService {
  RemoteGenerationService({
    required this.config,
    required this.httpClient,
    required this.authService,
  });

  final AppConfig config;
  final http.Client httpClient;
  final AuthService authService;

  @override
  Future<String> triggerGeneration({
    required String userId,
    required String mood,
  }) async {
    final url = Uri.parse(
      '${config.generationApiBaseUrl}${AppConstants.generateEndpoint}',
    );

    final idToken = await authService.getIdToken();

    final response = await httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'user_id': userId, 'mood': mood}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Generation API error ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final batchId = body['batch_id'] as String?;

    if (batchId == null || batchId.isEmpty) {
      throw Exception('Generation API returned no batch_id');
    }

    return batchId;
  }
}
