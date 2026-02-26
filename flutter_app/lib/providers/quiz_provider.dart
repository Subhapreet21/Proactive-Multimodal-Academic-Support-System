import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();

  List<Quiz> _quizzes = [];
  List<AIOverview> _overviews = [];
  bool _isLoading = false;
  String? _error;

  List<Quiz> get quizzes => _quizzes;
  List<AIOverview> get overviews => _overviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all available quizzes
  Future<void> loadQuizzes() async {
    _setLoading(true);
    _clearError();

    try {
      // Load quizzes first — this is the critical data
      _quizzes = await _quizService.getQuizzes();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return; // Can't go further without quizzes
    }

    // Load overviews independently — a failure here should not block the quiz list
    try {
      _overviews = await _quizService.getOverviews();
    } catch (_) {
      // Silently swallow overview errors (e.g. endpoint not yet deployed)
      _overviews = [];
    }

    _setLoading(false);
  }

  /// Trigger generation of a new Quiz from the KB
  Future<Quiz?> generateQuizFromKB(
    String kbArticleId, {
    int numQuestions = 5,
    DateTime? validFrom,
    DateTime? validUntil,
    int? timeLimitMins,
    String? targetYear,
    int? maxAttempts,
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
        maxAttempts: maxAttempts,
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

      // Update local quiz attempt count + lastAttempt for review mode
      final index = _quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        final existingQuiz = _quizzes[index];
        final newAttempt = result['attempt'] != null
            ? QuizAttempt.fromJson(result['attempt'] as Map<String, dynamic>)
            : null;
        _quizzes[index] = Quiz(
          id: existingQuiz.id,
          title: existingQuiz.title,
          description: existingQuiz.description,
          content: existingQuiz.content,
          createdAt: existingQuiz.createdAt,
          kbArticleId: existingQuiz.kbArticleId,
          validFrom: existingQuiz.validFrom,
          validUntil: existingQuiz.validUntil,
          timeLimitMins: existingQuiz.timeLimitMins,
          targetYear: existingQuiz.targetYear,
          maxAttempts: existingQuiz.maxAttempts,
          attemptsCount: existingQuiz.attemptsCount + 1,
          isActive: existingQuiz.isActive,
          lastAttempt: newAttempt ?? existingQuiz.lastAttempt,
        );
        notifyListeners();
      }

      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Trigger generation of a personalized AI insight overview
  Future<AIOverview?> generateOverview(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      final newOverview = await _quizService.generateOverview(quizId);

      // Update local list (replace if exists for this student/quiz, otherwise add)
      final existingIndex =
          _overviews.indexWhere((o) => o.id == newOverview.id);
      if (existingIndex != -1) {
        _overviews[existingIndex] = newOverview;
      } else {
        _overviews.insert(0, newOverview);
      }

      notifyListeners();
      return newOverview;
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
