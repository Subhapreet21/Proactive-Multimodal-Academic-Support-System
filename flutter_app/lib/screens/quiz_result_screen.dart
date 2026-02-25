import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz_model.dart';
import '../config/theme.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const QuizResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final attempt = resultData['attempt'] as QuizAttempt;
    final incorrectQuestions =
        resultData['incorrectQuestions'] as List<dynamic>;

    final percentage = (attempt.score / attempt.totalQuestions) * 100;
    final isPassed = percentage >= 60;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Force them to use the primary action button to leave
        title: const Text('Assessment Results',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Score Circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  border: Border.all(
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : AppTheme.errorColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPassed
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : AppTheme.errorColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${attempt.score}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isPassed
                              ? const Color(0xFF10B981)
                              : AppTheme.errorColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'out of ${attempt.totalQuestions}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // AI Feedback Nudge (Gap Analysis)
              if (attempt.feedback != null && attempt.feedback!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppTheme.primaryLight, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Gap Analysis',
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        attempt.feedback!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Incorrect Answers Breakdown
              if (incorrectQuestions.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Needs Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...incorrectQuestions.map((iq) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            iq['question'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.close,
                                  color: AppTheme.errorColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You chose: ${iq['selected']}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check,
                                  color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Correct: ${iq['correct']}',
                                  style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              iq['explanation'] ??
                                  'Review the material related to this concept.',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(
                        '/app/quizzes'); // Return to list via hard route to clear stack safely
                  },
                  icon: const Icon(Icons.keyboard_return_rounded),
                  label: const Text('Return to Quizzes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
