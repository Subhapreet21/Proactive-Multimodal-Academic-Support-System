class MessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  
  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'image': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
