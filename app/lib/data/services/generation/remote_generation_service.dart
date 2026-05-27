import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import 'generation_service.dart';
import '../../../core/constants/app_constants.dart';

/// Calls the remote generation API and returns the operationId.
/// Results arrive via a Firestore realtime subscription on history/{batchId}.
class RemoteGenerationService implements GenerationService {
  RemoteGenerationService({required this.config, required this.httpClient});

  final AppConfig config;
  final http.Client httpClient;

  @override
  Future<String> triggerGeneration({
    required String userId,
    required String mood,
  }) async {
    final url = Uri.parse(
      '${config.generationApiBaseUrl}${AppConstants.generateEndpoint}',
    );

    final response = await httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'mood': mood}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Generation API error ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final operationId = body['operationId'] as String?;

    if (operationId == null || operationId.isEmpty) {
      throw Exception('Generation API returned no operationId');
    }

    return operationId;
  }
}
