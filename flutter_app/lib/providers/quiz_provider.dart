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
  Future<Quiz?> generateQuizFromKB(
    String kbArticleId, {
    int numQuestions = 5,
    DateTime? validFrom,
    DateTime? validUntil,
    int? timeLimitMins,
    String? targetYear,
    bool isActive = true,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newQuiz = await _quizService.generateQuizFromKB(
        kbArticleId: kbArticleId,
        numQuestions: numQuestions,
        validFrom: validFrom,
        validUntil: validUntil,
        timeLimitMins: timeLimitMins,
        targetYear: targetYear,
        isActive: isActive,
      );
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

  /// Update an existing Quiz
  Future<void> updateQuiz(
      String quizId, Map<String, dynamic> updateData) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedQuiz = await _quizService.updateQuiz(quizId, updateData);
      // Find the existing quiz and replace it
      final index = _quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a Quiz
  Future<void> deleteQuiz(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      await _quizService.deleteQuiz(quizId);
      _quizzes.removeWhere((q) => q.id == quizId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
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
