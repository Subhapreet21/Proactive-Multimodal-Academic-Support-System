class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? eventDate;
  final String? location;
  final DateTime createdAt;
  
  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.eventDate,
    this.location,
    required this.createdAt,
  });
  
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date'])
          : null,
      location: json['location'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'event_date': eventDate?.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
