import 'api_service.dart';

class AttendanceService {
  final ApiService _api = ApiService();

  /// Fetch attendance records for a specific class slot on a given date.
  /// Used by Faculty to mark/view attendance.
  Future<Map<String, dynamic>> getClassAttendance(
      String timetableId, String date) async {
    try {
      final response = await _api.get(
        '/api/attendance/class',
        params: {'timetable_id': timetableId, 'date': date},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load class attendance: $e');
    }
  }

  /// Submit attendance records for a specific class slot on a given date.
  Future<Map<String, dynamic>> markAttendance({
    required String timetableId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final response = await _api.post(
        '/api/attendance/mark',
        {
          'timetable_id': timetableId,
          'date': date,
          'records': records,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// Fetch attendance statistics for a specific student.
  /// If [studentId] is null, fetches for the currently logged-in student.
  Future<Map<String, dynamic>> getStudentAttendance([String? studentId]) async {
    try {
      final params = studentId != null ? {'student_id': studentId} : null;
      final response = await _api.get(
        '/api/attendance/student',
        params: params,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load student attendance: $e');
    }
  }

  /// Fetch global attendance statistics for the Admin dashboard.
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _api.get('/api/attendance/admin/stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load admin attendance stats: $e');
    }
  }

  /// Alias for fetching student attendance stats including subject breakdown.
  Future<Map<String, dynamic>> getStudentStats(
      {required String studentId}) async {
    return getStudentAttendance(studentId);
  }

  /// Fetch overall percentage of all students filtered by department, year, section
  Future<List<dynamic>> getFilteredStudents({
    required String department,
    required String year,
    required String section,
  }) async {
    try {
      final response = await _api.get(
        '/api/attendance/filtered-students',
        params: {
          'department': department,
          'year': year,
          'section': section,
        },
      );
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load filtered students: $e');
    }
  }
}
