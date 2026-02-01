import 'api_service.dart';

class TourAssistantService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> askQuestion({
    required String sceneId,
    required String question,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/virtual-tour/ask',
        {
          'sceneId': sceneId,
          'question': question,
          'conversationHistory': conversationHistory ?? [],
        },
      );

      return {
        'answer': response['answer'] ?? 'No response received',
        'conversationId': response['conversationId'],
        'sceneContext': response['sceneContext'],
      };
    } catch (e) {
      throw Exception('Failed to get answer from tour assistant: $e');
    }
  }
}
