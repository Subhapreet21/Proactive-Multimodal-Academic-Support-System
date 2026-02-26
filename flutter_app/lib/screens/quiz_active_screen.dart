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
  final Map<String, String> _selectedAnswers = {};
  bool _isSubmitting = false;
  late bool _isFaculty;
  late bool _isReviewMode;

  // Timer State
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _isReviewMode = widget.reviewAttempt != null;
    _isFaculty = context.read<AuthProvider>().userRole == 'faculty' ||
        context.read<AuthProvider>().userRole == 'admin';

    if (_isReviewMode) {
      // In review mode, pre-fill the student's answers for highlighting
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
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
      // Auto-submit the moment the clock hits zero
      if (_remainingSeconds == 0) {
        timer.cancel();
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
    if (_isFaculty || _isReviewMode || _isSubmitting) return;
    setState(() => _selectedAnswers[questionId] = option);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.content.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  /// Shows the back / exit confirmation dialog for students
  Future<void> _handleBackPressed() async {
    if (_isFaculty || _isReviewMode) {
      context.go('/app/quizzes');
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Quiz?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'You have answered ${_selectedAnswers.length} of ${widget.quiz.content.length} questions.\nDo you want to submit your current answers or leave without recording an attempt?',
          style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'leave'),
            child: const Text('Leave Without Submitting',
                style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'submit'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Submit & Leave',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'leave') {
      context.go('/app/quizzes');
    } else if (action == 'submit') {
      await _submitQuiz(forceSubmit: true);
    }
    // 'cancel' does nothing
  }

  Future<void> _submitQuiz({bool forceSubmit = false}) async {
    if (_isFaculty || _isReviewMode) return;

    if (!forceSubmit) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Submit Quiz?',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'You have answered ${_selectedAnswers.length} out of ${widget.quiz.content.length} questions.',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final formattedAnswers = _selectedAnswers.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();

      final result = await context
          .read<QuizProvider>()
          .submitQuizAttempt(widget.quiz.id, formattedAnswers);

      if (mounted && result != null) {
        context.go('/app/quizzes/result', extra: {
          ...result,
          'quiz': widget.quiz,
        });
      } else if (mounted) {
        // Submission failed silently, go back to quizzes
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Submission failed. Please try again.'),
            backgroundColor: Colors.redAccent));
        context.go('/app/quizzes');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Submission failed: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.errorColor));
      }
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

    String formatTime(int totalSeconds) {
      int m = totalSeconds ~/ 60;
      int s = totalSeconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: _handleBackPressed,
          ),
          title: _buildAppBarTitle(questions, formatTime),
          centerTitle: true,
          actions: _buildAppBarActions(),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Container(
                height: 4,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(_isReviewMode
                      ? Colors.tealAccent
                      : AppTheme.primaryColor),
                ),
              ),

              // Question dot navigator
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    questions.length,
                    (i) {
                      final qId = questions[i]['id'];
                      final isAnswered = _selectedAnswers.containsKey(qId);
                      final isCurrent = i == _currentQuestionIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _currentQuestionIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : isAnswered
                                    ? AppTheme.primaryLight.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.15),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number + attempts chip + submit button — one row
                      Row(
                        children: [
                          // Question pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Attempts chip (students only)
                          if (!_isFaculty &&
                              !_isReviewMode &&
                              widget.quiz.maxAttempts != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.replay,
                                      size: 13, color: Colors.white60),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.quiz.attemptsCount + 1}/${widget.quiz.maxAttempts}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),

                          // Submit button (students only)
                          if (!_isFaculty && !_isReviewMode)
                            _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : ElevatedButton.icon(
                                    onPressed: () => _submitQuiz(),
                                    icon: const Icon(Icons.check_circle_rounded,
                                        size: 14, color: Colors.white),
                                    label: const Text('Submit',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                  ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Question text
                      Text(
                        currentQuestion['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Options
                      ...(currentQuestion['options'] as List<dynamic>)
                          .map((option) {
                        final optionStr = option.toString();
                        final qId = currentQuestion['id'];
                        final correctAnswer =
                            currentQuestion['correctAnswer']?.toString();
                        final selected = _selectedAnswers[qId];
                        final isSelected = selected == optionStr;
                        final isCorrect = optionStr == correctAnswer;
                        final showHighlight = _isFaculty || _isReviewMode;

                        // Determine styling
                        Color cardColor;
                        Color borderColor;
                        Color textColor;
                        IconData icon;
                        Color iconColor;

                        if (showHighlight && isCorrect) {
                          cardColor = Colors.green.withOpacity(0.15);
                          borderColor = Colors.greenAccent;
                          textColor = Colors.greenAccent;
                          icon = Icons.check_circle_rounded;
                          iconColor = Colors.greenAccent;
                        } else if (_isReviewMode && isSelected && !isCorrect) {
                          cardColor = AppTheme.errorColor.withOpacity(0.15);
                          borderColor = AppTheme.errorColor;
                          textColor = AppTheme.errorColor;
                          icon = Icons.cancel_rounded;
                          iconColor = AppTheme.errorColor;
                        } else if (isSelected) {
                          cardColor = AppTheme.primaryColor.withOpacity(0.2);
                          borderColor = AppTheme.primaryColor;
                          textColor = Colors.white;
                          icon = Icons.radio_button_checked;
                          iconColor = AppTheme.primaryLight;
                        } else {
                          cardColor = Colors.white.withOpacity(0.04);
                          borderColor = Colors.white.withOpacity(0.1);
                          textColor = Colors.white.withOpacity(0.9);
                          icon = Icons.radio_button_unchecked;
                          iconColor = Colors.white38;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: (_isFaculty || _isReviewMode)
                                    ? null
                                    : () => _handleOptionSelected(
                                        qId.toString(), optionStr),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(icon, color: iconColor, size: 22),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          optionStr,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: textColor,
                                            fontWeight:
                                                isCorrect && showHighlight
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      // Show explanation in review/faculty mode
                      if (((_isFaculty && !_isReviewMode) || _isReviewMode) &&
                          currentQuestion['explanation'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentQuestion['explanation'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade200,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar (Prev / Next only)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.9),
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.07))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _currentQuestionIndex > 0 ? _prevQuestion : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _currentQuestionIndex < questions.length - 1
                          ? _nextQuestion
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                      iconAlignment: IconAlignment.end,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(
      List<dynamic> questions, String Function(int) formatTime) {
    if (_isReviewMode) {
      return const Text('Attempt Review',
          style:
              TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold));
    }
    if (_isFaculty) {
      return const Text('Faculty Preview',
          style: TextStyle(
              color: AppTheme.secondaryColor, fontWeight: FontWeight.bold));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.quiz.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.quiz.timeLimitMins != null && widget.quiz.timeLimitMins! > 0)
          Text(
            formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 13,
              color: _remainingSeconds < 60 ? Colors.redAccent : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // Actions now live in the question header row (see body), not the AppBar
  List<Widget> _buildAppBarActions() => [];
}
