class Quiz {
  final String id;
  final String title;
  final String description;
  final String? kbArticleId;
  final String? kbArticleTitle;
  final List<dynamic> content; // The JSONB questions array
  final DateTime createdAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? timeLimitMins;
  final String? targetYear;
  final String? targetDepartment;
  final int? maxAttempts;
  final int attemptsCount;
  final bool isActive;
  final QuizAttempt? lastAttempt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.kbArticleId,
    this.kbArticleTitle,
    required this.content,
    required this.createdAt,
    this.validFrom,
    this.validUntil,
    this.timeLimitMins,
    this.targetYear,
    this.targetDepartment,
    this.maxAttempts,
    this.attemptsCount = 0,
    this.isActive = true,
    this.lastAttempt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'] ?? 'Untitled Quiz',
      description: json['description'] ?? '',
      kbArticleId: json['kb_article_id'],
      kbArticleTitle:
          json['kb_articles'] != null ? json['kb_articles']['title'] : null,
      content: json['content'] as List<dynamic>? ?? [],
      createdAt: DateTime.parse(json['created_at']),
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'])
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      timeLimitMins: json['time_limit_mins'],
      targetYear: json['target_year'] as String?,
      targetDepartment: json['target_department'] as String?,
      maxAttempts: json['max_attempts'] as int?,
      attemptsCount: json['attempts_count'] ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      lastAttempt: json['last_attempt'] != null
          ? QuizAttempt.fromJson(json['last_attempt'])
          : null,
    );
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final int score;
  final int totalQuestions;
  final String? feedback;
  final DateTime createdAt;
  final List<dynamic>? answers;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    this.feedback,
    required this.createdAt,
    this.answers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      feedback: json['feedback'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0),
      answers: json['answers'] as List<dynamic>?,
    );
  }
}

class AIOverview {
  final String id;
  final String quizId;
  final String quizTitle;
  final String studentId;
  final String studentName;
  final String studentSummary;
  final String facultySummary;
  final int? latestScore;
  final int? totalQuestions;
  final DateTime updatedAt;

  AIOverview({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.studentId,
    required this.studentName,
    required this.studentSummary,
    required this.facultySummary,
    this.latestScore,
    this.totalQuestions,
    required this.updatedAt,
  });

  factory AIOverview.fromJson(Map<String, dynamic> json) {
    return AIOverview(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      quizTitle: json['quizzes']?['title'] ?? 'Unknown Quiz',
      studentId: json['student_id'] as String,
      studentName: json['profiles']?['full_name'] ?? 'Unknown Student',
      studentSummary: json['student_summary'] as String? ?? '',
      facultySummary: json['faculty_summary'] as String? ?? '',
      latestScore: json['latest_score'] as int?,
      totalQuestions: json['total_questions'] as int?,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}
