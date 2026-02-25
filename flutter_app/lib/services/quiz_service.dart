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
  Future<Quiz> generateQuizFromKB(String kbArticleId, int numQuestions) async {
    try {
      final response = await _api.post(
        '/api/quizzes/generate',
        {
          'kb_article_id': kbArticleId,
          'num_questions': numQuestions,
        },
        requireAuth: true,
      );

      return Quiz.fromJson(response['quiz']);
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }

  /// Submit a quiz attempt and get real-time AI feedback
  Future<Map<String, dynamic>> submitAttempt(
      String quizId, List<Map<String, String>> answers) async {
    try {
      final response = await _api.post(
        '/api/quizzes/attempt',
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
}
