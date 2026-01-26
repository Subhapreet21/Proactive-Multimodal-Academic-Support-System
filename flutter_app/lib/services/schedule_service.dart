import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

import 'api_service.dart';

class ScheduleService {
  final ApiService _api = ApiService();
  static const String _key = 'timetable_structure';

  // Default Schedule
  static final List<Map<String, dynamic>> defaultSchedule = [
    {'start': '09:00', 'end': '10:00', 'type': 'class'},
    {'start': '10:00', 'end': '11:00', 'type': 'class'},
    {'start': '11:00', 'end': '11:10', 'type': 'break', 'label': 'Short Break'},
    {'start': '11:10', 'end': '12:10', 'type': 'class'},
    {'start': '12:10', 'end': '13:00', 'type': 'break', 'label': 'Lunch Break'},
    {'start': '13:00', 'end': '14:00', 'type': 'class'},
    {'start': '14:00', 'end': '15:00', 'type': 'class'},
  ];

  Future<void> saveSchedule(List<Map<String, dynamic>> schedule,
      {String? department}) async {
    // Build endpoint with department query param
    final endpoint = department != null
        ? '/api/timetable/structure?department=$department'
        : '/api/timetable/structure';

    // 1. Save to Backend
    try {
      await _api.post(endpoint, schedule);
      debugPrint(
          '✅ Saved structure to backend${department != null ? " for $department" : ""}');
    } catch (e) {
      debugPrint('Failed to save structure to backend: $e');
      // Continue to save locally even if backend fails (optimistic)
    }

    // 2. Save Locally with department-specific key
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        department != null ? 'timetable_structure_$department' : _key;
    final String jsonString = jsonEncode(schedule);
    await prefs.setString(cacheKey, jsonString);
  }

  Future<List<Map<String, dynamic>>> getSchedule({String? department}) async {
    final prefs = await SharedPreferences.getInstance();

    // Build endpoint with department query param
    final endpoint = department != null
        ? '/api/timetable/structure?department=$department'
        : '/api/timetable/structure';

    // 1. Try to fetch from Backend
    try {
      final response = await _api.get(endpoint);
      if (response != null && response is List) {
        final List<Map<String, dynamic>> remoteSchedule =
            response.map((e) => Map<String, dynamic>.from(e)).toList();

        // Update Local Cache with department-specific key
        final cacheKey =
            department != null ? 'timetable_structure_$department' : _key;
        await prefs.setString(cacheKey, jsonEncode(remoteSchedule));
        debugPrint(
            '✅ Fetched structure from backend${department != null ? " for $department" : ""}');
        return remoteSchedule;
      }
    } catch (e) {
      debugPrint('Failed to fetch structure from backend: $e');
      // Fallback to local
    }

    // 2. Fallback to Local Cache with department-specific key
    final cacheKey =
        department != null ? 'timetable_structure_$department' : _key;
    final String? jsonString = prefs.getString(cacheKey);

    if (jsonString == null) {
      debugPrint('⚠️ No cached structure, using default');
      return List<Map<String, dynamic>>.from(defaultSchedule);
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return List<Map<String, dynamic>>.from(defaultSchedule);
    }
  }

  Future<Map<String, dynamic>> batchUpdateEntries(
      List<Map<String, dynamic>> entries) async {
    try {
      debugPrint('🌐 API: POST /api/timetable/batch_update');
      debugPrint('🌐 Payload: ${entries.length} entries');
      debugPrint('🌐 Sample: ${entries.take(2).toList()}');

      final result =
          await _api.post('/api/timetable/batch_update', {'entries': entries});

      debugPrint('🌐 API Success: $result');
      return result;
    } catch (e) {
      debugPrint('🌐 API Error: $e');
      throw e;
    }
  }
}
