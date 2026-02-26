import '../models/quiz_model.dart';
import 'api_service.dart';

class QuizService {
  final ApiService _api = ApiService();

  /// Fetch all available quizzes
  Future<List<Quiz>> getQuizzes() async {
    try {
      final response = await _api.get('/api/quizzes', requireAuth: true);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => Quiz.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch quizzes: $e');
    }
  }

  /// Generate a new quiz from a Knowledge Base article
  Future<Quiz> generateQuizFromKB({
    required String kbArticleId,
    required int numQuestions,
    DateTime? validFrom,
    DateTime? validUntil,
    int? timeLimitMins,
    String? targetYear,
    int? maxAttempts,
    bool isActive = true,
  }) async {
    try {
      final payload = {
        'kb_article_id': kbArticleId,
        'num_questions': numQuestions,
        if (validFrom != null) 'valid_from': validFrom.toIso8601String(),
        if (validUntil != null) 'valid_until': validUntil.toIso8601String(),
        if (timeLimitMins != null) 'time_limit_mins': timeLimitMins,
        if (targetYear != null) 'target_year': targetYear,
        if (maxAttempts != null) 'max_attempts': maxAttempts,
        'is_active': isActive,
      };

      final response = await _api.post(
        '/api/quizzes/generate',
        payload,
        requireAuth: true,
      );

      return Quiz.fromJson(response['quiz']);
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }

  /// Update an existing quiz
  Future<Quiz> updateQuiz(
      String quizId, Map<String, dynamic> updateData) async {
    try {
      final response = await _api.put(
        '/api/quizzes/$quizId',
        updateData,
        requireAuth: true,
      );
      return Quiz.fromJson(response['quiz']);
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _api.delete(
        '/api/quizzes/$quizId',
        requireAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }

  /// Submit a quiz attempt and get real-time AI feedback
  Future<Map<String, dynamic>> submitAttempt(
      String quizId, List<Map<String, String>> answers) async {
    try {
      final response = await _api.post(
        '/api/quizzes/attempts',
        {
          'quiz_id': quizId,
          'answers': answers,
        },
        requireAuth: true,
      );

      return {
        'attempt': QuizAttempt.fromJson(response['attempt']),
        'incorrectQuestions': response['incorrectQuestions'] as List<dynamic>,
      };
    } catch (e) {
      throw Exception('Failed to submit quiz attempt: $e');
    }
  }

  /// Get generated AI Overviews
  Future<List<AIOverview>> getOverviews() async {
    try {
      final response =
          await _api.get('/api/quizzes/overviews', requireAuth: true);
      return (response as List)
          .map((json) => AIOverview.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load overviews: $e');
    }
  }

  /// Trigger generation of a personalized AI overview
  Future<AIOverview> generateOverview(String quizId) async {
    try {
      final response = await _api.post(
        '/api/quizzes/$quizId/generate-overview',
        {},
        requireAuth: true,
      );
      return AIOverview.fromJson(response['overview']);
    } catch (e) {
      throw Exception('Failed to generate overview: $e');
    }
  }
}
