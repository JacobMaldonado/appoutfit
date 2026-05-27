abstract class GenerationService {
  /// Calls the generation API and returns the operationId (batchId).
  /// Results are delivered via Firestore realtime stream — not from this call.
  Future<String> triggerGeneration({
    required String userId,
    required String mood,
  });
}
