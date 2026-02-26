import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/quiz_model.dart';
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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quizProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(
                        bottom: 16, left: 20, right: 20, top: 12),
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

                // --- TAB BAR ---
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Quizzes'),
                      Tab(text: 'AI Insights'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Assessments
                      quizProvider.quizzes.isEmpty && !quizProvider.isLoading
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async =>
                                  context.read<QuizProvider>().loadQuizzes(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: quizProvider.quizzes.length,
                                itemBuilder: (context, index) {
                                  final quiz = quizProvider.quizzes[index];
                                  return _buildQuizCard(
                                      quiz, isFaculty, context);
                                },
                              ),
                            ),

                      // Tab 2: AI Insights
                      quizProvider.overviews.isEmpty && !quizProvider.isLoading
                          ? _buildEmptyInsightsState()
                          : RefreshIndicator(
                              onRefresh: () async =>
                                  context.read<QuizProvider>().loadQuizzes(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: quizProvider.overviews.length,
                                itemBuilder: (context, index) {
                                  final overview =
                                      quizProvider.overviews[index];
                                  return _buildOverviewCard(overview, isFaculty,
                                      quizProvider.quizzes);
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildEmptyInsightsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No AI Insights Generated',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete an assessment to unlock personalized insights.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(dynamic quiz, bool isFaculty, BuildContext context) {
    final now = DateTime.now();
    final isQuizExpired =
        quiz.validUntil != null && (quiz.validUntil as DateTime).isBefore(now);
    final isQuizInactive = !(quiz.isActive as bool? ?? false);

    final isExpired = !isFaculty && isQuizExpired;
    final isInactive = !isFaculty && isQuizInactive;
    final isDisabled = isExpired || isInactive;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05), // Subtle tint
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDisabled
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1)),
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
                  // Block expired or inactive quizzes for students
                  if (isDisabled) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          isExpired
                              ? 'This quiz has expired and is no longer available.'
                              : 'This quiz has been deactivated by your instructor.',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.errorColor,
                    ));
                    return;
                  }
                  // If they maxed attempts, they can't retake it
                  if (!isFaculty &&
                      quiz.maxAttempts != null &&
                      quiz.attemptsCount >= quiz.maxAttempts) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Maximum attempts reached.',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.errorColor,
                    ));
                    return;
                  }
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
                                      style: TextStyle(
                                          color: AppTheme.errorColor)),
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
                          Expanded(
                            child: Builder(builder: (context) {
                              Widget buildMetaBadge({
                                required IconData icon,
                                required String text,
                                required Color color,
                              }) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: color.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon,
                                          size: 14,
                                          color: color.withOpacity(0.9)),
                                      const SizedBox(width: 4),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: color.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: 12, // Horizontal spacing between items
                                runSpacing:
                                    10, // Vertical spacing if it wraps to next line
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Questions
                                  buildMetaBadge(
                                    icon: Icons.format_list_numbered,
                                    text: '${quiz.content.length} Questions',
                                    color: Colors.white,
                                  ),

                                  // Attempts — show as fraction for students, "Max X" for faculty
                                  if (quiz.maxAttempts != null)
                                    buildMetaBadge(
                                      icon: Icons.replay,
                                      text: isFaculty
                                          ? 'Max ${quiz.maxAttempts} attempts'
                                          : '${quiz.attemptsCount}/${quiz.maxAttempts} attempts',
                                      color: isFaculty
                                          ? Colors.white
                                          : (quiz.attemptsCount >=
                                                  quiz.maxAttempts!
                                              ? Colors.redAccent
                                              : Colors.amberAccent),
                                    ),

                                  // Time
                                  buildMetaBadge(
                                    icon: Icons.schedule,
                                    text: timeago.format(quiz.createdAt),
                                    color: Colors.white,
                                  ),

                                  // Year Badge (Faculty Only)
                                  if (isFaculty && quiz.targetYear != null)
                                    buildMetaBadge(
                                      icon: Icons.people_alt,
                                      text: quiz.targetYear == 'All'
                                          ? 'All Years'
                                          : 'Year ${quiz.targetYear}',
                                      color: Colors.purpleAccent,
                                    ),

                                  // Valid date range chip
                                  if (quiz.validFrom != null ||
                                      quiz.validUntil != null)
                                    buildMetaBadge(
                                      icon: isQuizExpired
                                          ? Icons.event_busy
                                          : Icons.date_range,
                                      text: () {
                                        String fmt(DateTime d) =>
                                            '${d.day}/${d.month}/${d.year}';
                                        if (quiz.validFrom != null &&
                                            quiz.validUntil != null) {
                                          return '${fmt(quiz.validFrom)} – ${fmt(quiz.validUntil)}';
                                        } else if (quiz.validFrom != null) {
                                          return 'From ${fmt(quiz.validFrom)}';
                                        } else {
                                          return 'Until ${fmt(quiz.validUntil)}';
                                        }
                                      }(),
                                      color: isQuizExpired
                                          ? Colors.redAccent
                                          : Colors.cyanAccent,
                                    ),

                                  // Expired badge
                                  if (isQuizExpired)
                                    buildMetaBadge(
                                      icon: Icons.block,
                                      text: 'Expired',
                                      color: Colors.redAccent,
                                    ),

                                  // Active/Inactive badge
                                  if (isFaculty)
                                    buildMetaBadge(
                                      icon: isQuizInactive
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      text: isQuizInactive
                                          ? 'Inactive'
                                          : 'Active',
                                      color: isQuizInactive
                                          ? Colors.orange
                                          : Colors.green,
                                    )
                                  else if (isQuizInactive && !isQuizExpired)
                                    buildMetaBadge(
                                      icon: Icons.visibility_off,
                                      text: 'Inactive',
                                      color: Colors.orange,
                                    ),
                                ],
                              );
                            }),
                          ),
                          if (quiz.kbArticleId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.greenAccent.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 14, color: Colors.greenAccent),
                                  const SizedBox(width: 4),
                                  const Text('AI Gen',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          if (quiz.description != null &&
                              quiz.description!
                                  .contains('Imported via bulk Excel upload'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4FC3F7).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.table_view_rounded,
                                      size: 14, color: Color(0xFF4FC3F7)),
                                  const SizedBox(width: 4),
                                  const Text('Excel',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4FC3F7),
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // BOTTOM BUTTONS (for Students)
                      if (!isFaculty && quiz.attemptsCount > 0) ...[
                        const SizedBox(height: 16),
                        // -- Row 1: Reattempt + Review --
                        Row(
                          children: [
                            // Reattempt button — only if attempts remaining
                            if (quiz.maxAttempts == null ||
                                quiz.attemptsCount < quiz.maxAttempts!) ...[
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => context.go(
                                          '/app/quizzes/active',
                                          extra: quiz),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.refresh_rounded,
                                                size: 16, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                quiz.maxAttempts != null
                                                    ? 'Retry (${quiz.attemptsCount}/${quiz.maxAttempts})'
                                                    : 'Retry',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Review button — always visible after an attempt
                            if (quiz.lastAttempt != null)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        context.push('/app/quizzes/active',
                                            extra: {
                                              'quiz': quiz,
                                              'reviewAttempt': quiz.lastAttempt,
                                            });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.history,
                                                size: 16,
                                                color: Colors.white70),
                                            SizedBox(width: 8),
                                            Text('Review',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // -- Row 2: New AI Insight (full width) --
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppTheme.secondaryColor.withOpacity(0.3)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final success = await context
                                    .read<QuizProvider>()
                                    .generateOverview(quiz.id);
                                if (success != null && context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: const Row(children: [
                                      Icon(Icons.auto_awesome,
                                          color: Colors.amber, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                          "AI Insight Generated! Check the 'AI Insights' tab.",
                                          style: TextStyle(color: Colors.white))
                                    ]),
                                    backgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.9),
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.auto_awesome,
                                        size: 16,
                                        color: AppTheme.secondaryColor),
                                    SizedBox(width: 8),
                                    Text('Generate Latest AI Insight',
                                        style: TextStyle(
                                            color: AppTheme.secondaryColor,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
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

  Widget _buildOverviewCard(
      AIOverview overview, bool isFaculty, List<Quiz> quizzes) {
    // Resolve quiz title from loaded quizzes when backend join returns null
    final resolvedTitle = (overview.quizTitle == 'Unknown Quiz' ||
            overview.quizTitle.isEmpty)
        ? (quizzes
                .cast<Quiz?>()
                .firstWhere((q) => q!.id == overview.quizId, orElse: () => null)
                ?.title ??
            'Unknown Quiz')
        : overview.quizTitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                      child:
                          const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFaculty
                                ? "Student: ${overview.studentName}"
                                : "Your Performance Summary",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeago.format(overview.updatedAt),
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    isFaculty
                        ? overview.facultySummary
                        : overview.studentSummary,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                ),
                // Score tile (when score data is available)
                if (overview.latestScore != null &&
                    overview.totalQuestions != null)
                  Builder(builder: (context) {
                    final pct = overview.totalQuestions! > 0
                        ? (overview.latestScore! /
                                overview.totalQuestions! *
                                100)
                            .round()
                        : 0;
                    final scoreColor = pct >= 70
                        ? Colors.greenAccent
                        : pct >= 40
                            ? Colors.amberAccent
                            : Colors.redAccent;
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(
                            pct >= 70
                                ? Icons.emoji_events_rounded
                                : pct >= 40
                                    ? Icons.trending_up
                                    : Icons.warning_amber_rounded,
                            size: 20,
                            color: scoreColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Latest Score: ${overview.latestScore}/${overview.totalQuestions} ($pct%)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ]),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
