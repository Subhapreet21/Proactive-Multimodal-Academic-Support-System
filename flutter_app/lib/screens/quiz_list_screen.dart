import 'dart:ui';
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Test your knowledge and get real-time AI feedback',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    if (quizProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (quizProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.5)),
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
      ),
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
        color: AppTheme.primaryColor.withOpacity(0.05), // Subtle tint
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.go('/app/quizzes/active', extra: quiz);
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
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
                        if (isFaculty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70),
                            color: const Color(0xFF1E293B),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditQuizModal(context, quiz);
                              } else if (value == 'delete') {
                                _deleteQuizConfirm(context, quiz);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Settings',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Quiz',
                                    style:
                                        TextStyle(color: AppTheme.errorColor)),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_list_numbered,
                                size: 16, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(
                              '${quiz.content.length} Questions',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 16),
                            if (quiz.maxAttempts != null) ...[
                              Icon(Icons.replay,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.5)),
                              const SizedBox(width: 6),
                              Text(
                                'Max ${quiz.maxAttempts}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Icon(Icons.schedule,
                                size: 16, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text(
                              timeago.format(quiz.createdAt),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                        if (quiz.kbArticleId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppTheme.secondaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 14, color: AppTheme.secondaryColor),
                                const SizedBox(width: 4),
                                const Text('AI Gen',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.secondaryColor,
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
        ),
      ),
    );
  }

  void _deleteQuizConfirm(BuildContext context, dynamic quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Quiz', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${quiz.title}"?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<QuizProvider>().deleteQuiz(quiz.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showEditQuizModal(BuildContext context, dynamic quiz) {
    DateTime? validFrom = quiz.validFrom;
    DateTime? validUntil = quiz.validUntil;
    int? timeLimitMins = quiz.timeLimitMins;
    String? targetYear = quiz.targetYear;
    int? maxAttempts = quiz.maxAttempts;
    bool isActive = quiz.isActive;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24),
            decoration: const BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Quiz Settings',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Update constraints and metadata.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Valid Dates
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dates: ${validFrom != null && validUntil != null ? "${validFrom!.day}/${validFrom!.month} - ${validUntil!.day}/${validUntil!.month}" : "Not Set"}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange:
                              validFrom != null && validUntil != null
                                  ? DateTimeRange(
                                      start: validFrom!, end: validUntil!)
                                  : null,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            validFrom = picked.start;
                            validUntil = picked.end;
                          });
                        }
                      },
                      child: const Text('Set Dates',
                          style: TextStyle(color: const Color(0xFF10B981))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time Limit and Year
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: timeLimitMins?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Duration (mins)',
                          labelStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          setModalState(
                              () => timeLimitMins = int.tryParse(val));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: targetYear,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          labelText: 'Target Year',
                          labelStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: ['All', '1', '2', '3', '4']
                            .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(
                                    y == 'All' ? 'All Years' : 'Year $y',
                                    style:
                                        const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (val) {
                          setModalState(() => targetYear = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max Attempts
                TextFormField(
                  initialValue: maxAttempts?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Max Attempts (Leave blank for unlimited)',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setModalState(() => maxAttempts = int.tryParse(val));
                  },
                ),
                const SizedBox(height: 16),

                // Is Active Switch
                SwitchListTile(
                  title: Text('Active / Visible to Students',
                      style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  value: isActive,
                  activeColor: const Color(0xFF10B981),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setModalState(() => isActive = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<QuizProvider>().updateQuiz(quiz.id, {
                        'valid_from': validFrom?.toIso8601String(),
                        'valid_until': validUntil?.toIso8601String(),
                        'time_limit_mins': timeLimitMins,
                        'target_year': targetYear,
                        'max_attempts': maxAttempts,
                        'is_active': isActive,
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
