import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch quizzes when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final isFaculty = context.read<AuthProvider>().userRole == 'faculty' ||
        context.read<AuthProvider>().userRole == 'admin';

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background set by AppShell gradient
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quizzes & Assessments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (quizProvider.isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge and get real-time AI feedback',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              if (quizProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.errorColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quizProvider.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: quizProvider.quizzes.isEmpty && !quizProvider.isLoading
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            context.read<QuizProvider>().loadQuizzes(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: quizProvider.quizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = quizProvider.quizzes[index];
                            return _buildQuizCard(quiz, isFaculty, context);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isFaculty
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/app/quizzes/manage');
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add_task),
              label: const Text('Create Quiz',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No Quizzes Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your instructors haven\'t posted any quizzes yet.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(dynamic quiz, bool isFaculty, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go('/app/quizzes/active', extra: quiz);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz.description.isNotEmpty
                                ? quiz.description
                                : 'Test your knowledge on this topic.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_list_numbered,
                            size: 16, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.content.length} Questions',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule,
                            size: 16, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(quiz.createdAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    if (quiz.kbArticleId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withOpacity(0.2), // Emerald green
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            const Text('AI Generated',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
