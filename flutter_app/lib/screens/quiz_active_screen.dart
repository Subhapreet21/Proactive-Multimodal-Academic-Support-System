import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class QuizActiveScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt? reviewAttempt;

  const QuizActiveScreen({super.key, required this.quiz, this.reviewAttempt});

  @override
  State<QuizActiveScreen> createState() => _QuizActiveScreenState();
}

class _QuizActiveScreenState extends State<QuizActiveScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, String> _selectedAnswers =
      {}; // questionId -> selectedOption
  bool _isSubmitting = false;
  late bool _isFaculty;

  // Timer State
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _isFaculty = context.read<AuthProvider>().userRole == 'faculty' ||
        context.read<AuthProvider>().userRole == 'admin';

    if (widget.reviewAttempt != null) {
      _isFaculty = true; // Review mode behaves like faculty preview natively
      if (widget.reviewAttempt!.answers != null) {
        for (var ans in widget.reviewAttempt!.answers!) {
          if (ans is Map) {
            _selectedAnswers[ans['questionId']] = ans['selectedOption'];
          }
        }
      }
    } else if (!_isFaculty &&
        widget.quiz.timeLimitMins != null &&
        widget.quiz.timeLimitMins! > 0) {
      _remainingSeconds = widget.quiz.timeLimitMins! * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(forceSubmit: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleOptionSelected(String questionId, String option) {
    if (_isFaculty || _isSubmitting)
      return; // Prevent interaction for faculty or when submitting

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

  Future<void> _submitQuiz({bool forceSubmit = false}) async {
    if (_isFaculty) return; // Faculty cannot submit

    if (!forceSubmit) {
      // Show confirmation dialog first
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title:
              Text('Submit Quiz?', style: const TextStyle(color: Colors.white)),
          content: Text(
            'You have answered ${_selectedAnswers.length} out of ${widget.quiz.content.length} questions.',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

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
        context.go('/app/quizzes/result', extra: {
          ...result,
          'quiz': widget.quiz,
        });
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

    // Format Time Function
    String formatTime(int totalSeconds) {
      int m = totalSeconds ~/ 60;
      int s = totalSeconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isFaculty
            ? Text(
                widget.reviewAttempt != null
                    ? 'Attempt Review'
                    : 'Faculty Preview',
                style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold))
            : Column(
                children: [
                  Text(
                      'Question ${_currentQuestionIndex + 1} / ${questions.length}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  if (widget.quiz.timeLimitMins != null &&
                      widget.quiz.timeLimitMins! > 0)
                    Text(formatTime(_remainingSeconds),
                        style: TextStyle(
                            fontSize: 14,
                            color: _remainingSeconds < 60
                                ? Colors.redAccent
                                : Colors.white70,
                            fontWeight: FontWeight.bold)),
                ],
              ),
        centerTitle: true,
        actions: [
          if (!_isFaculty && widget.quiz.maxAttempts != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Attempt ${widget.quiz.attemptsCount + 1}/${widget.quiz.maxAttempts}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
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
                      final isStudentReview = widget.reviewAttempt != null;

                      // Highlighting Logic
                      final isCorrectOption = (_isFaculty || isStudentReview) &&
                          option == currentQuestion['correctOption'];
                      final isStudentWrongSelection =
                          isStudentReview && isSelected && !isCorrectOption;

                      Color cardColor = isSelected
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05);
                      Color borderColor = isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withOpacity(0.1);
                      Color textColor = isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.9);
                      IconData iconData = isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked;
                      Color iconColor =
                          isSelected ? AppTheme.primaryLight : Colors.white54;

                      if (isCorrectOption) {
                        cardColor = Colors.green.withOpacity(0.2);
                        borderColor = Colors.greenAccent;
                        textColor = Colors.greenAccent;
                        iconData = Icons.check_circle;
                        iconColor = Colors.greenAccent;
                      } else if (isStudentWrongSelection) {
                        cardColor = AppTheme.errorColor.withOpacity(0.2);
                        borderColor = AppTheme.errorColor;
                        textColor = AppTheme.errorColor;
                        iconData = Icons.cancel;
                        iconColor = AppTheme.errorColor;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: borderColor,
                                width: isSelected || isCorrectOption ? 2 : 1),
                          ),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isFaculty
                                  ? null
                                  : () => _handleOptionSelected(
                                      currentQuestion['id'], option.toString()),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5), // Added glassmorphism
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(iconData, color: iconColor),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              option.toString(),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: textColor,
                                                  fontWeight: isCorrectOption
                                                      ? FontWeight.bold
                                                      : FontWeight.normal),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))),
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
                  color: const Color(0xFF1E293B)
                      .withOpacity(0.8), // Glassmorphism base
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed:
                              _currentQuestionIndex > 0 ? _prevQuestion : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text("Previous"),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              disabledForegroundColor:
                                  Colors.white.withOpacity(0.2)),
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
                        else if (!_isFaculty) // Hide submit from faculty
                          ElevatedButton.icon(
                            onPressed:
                                _isSubmitting ? null : () => _submitQuiz(),
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
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
