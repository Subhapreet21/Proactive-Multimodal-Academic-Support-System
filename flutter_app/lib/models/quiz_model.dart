class Quiz {
  final String id;
  final String title;
  final String description;
  final String? kbArticleId;
  final String? kbArticleTitle;
  final List<dynamic> content; // The JSONB questions array
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.kbArticleId,
    this.kbArticleTitle,
    required this.content,
    required this.createdAt,
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

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    this.feedback,
    required this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quiz_id'],
      score: json['score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      feedback: json['feedback'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
