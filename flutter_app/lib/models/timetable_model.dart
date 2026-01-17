class TimetableEntry {
  final String id;
  final String courseCode;
  final String courseName;
  final String startTime;
  final String endTime;
  final String location;
  final String dayOfWeek;
  final String? faculty;
  final String? department;
  final String? year;
  final String? section;
  
  TimetableEntry({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.dayOfWeek,
    this.faculty,
    this.department,
    this.year,
    this.section,
  });
  
  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id']?.toString() ?? '',
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      location: json['location'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      faculty: json['faculty'],
      department: json['department'],
      year: json['year']?.toString(),
      section: json['section'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'day_of_week': dayOfWeek,
      'faculty': faculty,
      'department': department,
      'year': year,
      'section': section,
    };
  }
}
