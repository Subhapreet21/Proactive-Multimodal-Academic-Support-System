import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../config/theme.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  Map<String, dynamic>? _attendanceData;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final data = await _attendanceService.getStudentAttendance();
      if (mounted) {
        setState(() {
          _attendanceData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildOverviewCard() {
    final percentage = _attendanceData?['overallPercentage'] ?? 0;
    final totalClasses = _attendanceData?['totalClasses'] ?? 0;
    final totalPresent = _attendanceData?['totalPresent'] ?? 0;

    Color statusColor = AppTheme.successColor;
    if (totalClasses == 0)
      statusColor = Colors.white54;
    else if (percentage < 75)
      statusColor = AppTheme.errorColor;
    else if (percentage < 85) statusColor = AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Attendance',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  totalClasses == 0 ? 'N/A' : '$percentage%',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalPresent / $totalClasses classes attended',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: totalClasses == 0 ? 0 : percentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: statusColor,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Icon(
                    totalClasses == 0
                        ? Icons.horizontal_rule_rounded
                        : (percentage >= 85
                            ? Icons.check_circle_rounded
                            : (percentage >= 75
                                ? Icons.warning_rounded
                                : Icons.cancel_rounded)),
                    color: statusColor,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIForecast(String studentId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceService.getStudentAIForecast(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink(); // Hide silently on error
        }

        final data = snapshot.data!;
        final projectedPercentage = data['projectedPercentage'] ?? 0;
        final studentNudge =
            data['studentNudge'] ?? "Maintain your current attendance.";

        Color sColor = AppTheme.successColor;
        if (projectedPercentage < 75)
          sColor = AppTheme.errorColor;
        else if (projectedPercentage < 85) sColor = AppTheme.warningColor;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.15),
                const Color(0xFFA855F7).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFA855F7)),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Projected Path',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$projectedPercentage% Projected',
                      style: TextStyle(
                        color: sColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                studentNudge,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectBreakdown() {
    final breakdown = _attendanceData?['subjectBreakdown'] as List? ?? [];

    if (breakdown.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No attendance records found.',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Subject-wise Breakdown',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...breakdown.map((subject) {
          final pct = subject['percentage'] ?? 0;
          Color sColor = AppTheme.successColor;
          if (pct < 75)
            sColor = AppTheme.errorColor;
          else if (pct < 85) sColor = AppTheme.warningColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject['course'] ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                          '${subject['present']} / ${subject['total']} classes',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pct%',
                    style:
                        TextStyle(color: sColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentHistory() {
    final history = _attendanceData?['recentHistory'] as List? ?? [];

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Recent Classes',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...history.map((record) {
          final isPresent = record['status'] == 'present';
          final isLate = record['status'] == 'late';
          Color sColor = isPresent
              ? AppTheme.successColor
              : (isLate ? AppTheme.warningColor : AppTheme.errorColor);
          IconData icon = isPresent
              ? Icons.check_circle
              : (isLate ? Icons.access_time_filled : Icons.cancel);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(icon, color: sColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record['course'] ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(record['date'] ?? '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  (record['status'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                      color: sColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchAttendance,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    if (_attendanceData != null &&
                        _attendanceData!['studentId'] != null)
                      _buildAIForecast(_attendanceData!['studentId']),
                    const SizedBox(height: 16),
                    _buildRecentHistory(),
                    const SizedBox(height: 16),
                    _buildSubjectBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }
}
