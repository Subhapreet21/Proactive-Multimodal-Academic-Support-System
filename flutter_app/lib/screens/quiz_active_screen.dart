import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../config/theme.dart';

class QuizActiveScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizActiveScreen({super.key, required this.quiz});

  @override
  State<QuizActiveScreen> createState() => _QuizActiveScreenState();
}

class _QuizActiveScreenState extends State<QuizActiveScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, String> _selectedAnswers =
      {}; // questionId -> selectedOption
  bool _isSubmitting = false;

  void _handleOptionSelected(String questionId, String option) {
    setState(() {
      _selectedAnswers[questionId] = option;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.content.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('Submit Quiz?', style: TextStyle(color: Colors.white)),
        content: Text(
          'You have answered ${_selectedAnswers.length} out of ${widget.quiz.content.length} questions.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      // Format answers for backend
      final formattedAnswers = _selectedAnswers.entries
          .map((e) => {
                'questionId': e.key,
                'selectedOption': e.value,
              })
          .toList();

      final result = await context
          .read<QuizProvider>()
          .submitQuizAttempt(widget.quiz.id, formattedAnswers);

      if (mounted && result != null) {
        context.go('/app/quizzes/result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Submission failed: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.content;
    if (questions.isEmpty) {
      return const Scaffold(
          body: Center(child: Text("Invalid Quiz Structure")));
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            'Question ${_currentQuestionIndex + 1} of ${questions.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...(currentQuestion['options'] as List<dynamic>)
                        .map((option) {
                      final isSelected =
                          _selectedAnswers[currentQuestion['id']] == option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _handleOptionSelected(
                                currentQuestion['id'], option.toString()),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _currentQuestionIndex > 0 ? _prevQuestion : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text("Previous"),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withOpacity(0.2)),
                  ),
                  if (!isLastQuestion)
                    ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.black),
                      label: const Text("Next Question",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitQuiz,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded,
                              color: Colors.white),
                      label: Text(
                          _isSubmitting ? "Submitting..." : "Submit Quiz",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
