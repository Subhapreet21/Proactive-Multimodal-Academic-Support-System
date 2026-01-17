class ReminderModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dueAt;
  final String category;
  final bool isCompleted;
  final String userId;

  ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueAt,
    required this.category,
    this.isCompleted = false,
    required this.userId,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueAt: DateTime.parse(json['due_at']),
      category: json['category'] ?? 'Other',
      isCompleted: json['is_completed'] ?? false,
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_at': dueAt.toIso8601String(),
      'category': category,
      'is_completed': isCompleted,
      'user_id': userId,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueAt,
    String? category,
    bool? isCompleted,
    String? userId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
    );
  }
}
