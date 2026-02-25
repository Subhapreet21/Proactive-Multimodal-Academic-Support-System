import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();

  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  String? _error;

  List<Quiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all available quizzes
  Future<void> loadQuizzes() async {
    _setLoading(true);
    _clearError();

    try {
      _quizzes = await _quizService.getQuizzes();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Trigger generation of a new Quiz from the KB
  Future<Quiz?> generateQuizFromKB(String kbArticleId) async {
    _setLoading(true);
    _clearError();

    try {
      final newQuiz = await _quizService.generateQuizFromKB(kbArticleId);
      // Insert to the top of the list so it appears immediately
      _quizzes.insert(0, newQuiz);
      notifyListeners();
      return newQuiz;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Submit quiz answers and return AI feedback
  Future<Map<String, dynamic>?> submitQuizAttempt(
      String quizId, List<Map<String, String>> answers) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _quizService.submitAttempt(quizId, answers);
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // --- Internal State Helpers ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
