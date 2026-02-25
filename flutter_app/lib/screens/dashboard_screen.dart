import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/permissions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.get(AppConstants.dashboardEndpoint);
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silent error handling for dashboard refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final permissions = AppPermissions(authProvider);
    final user = authProvider.user;

    String greetingName;
    String subtext;

    if (permissions.isAdmin) {
      greetingName = 'Admin';
      subtext = 'God Mode: Manual overrides enabled.';
    } else if (permissions.isFaculty) {
      greetingName = 'Prof. ${user?.fullName?.split(' ').last ?? 'Faculty'}';
      subtext = 'Department of ${user?.department ?? 'Academics'}';
    } else {
      greetingName = user?.fullName?.split(' ').first ?? 'Student';
      subtext =
          'Section ${user?.section ?? 'A'} • ${user?.department ?? 'CSE'} Year ${user?.year ?? '1'}';
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Header
                          Text(
                            'Welcome back, $greetingName 👋',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtext,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryLight.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Quick Stats Grid
                          _buildNextClassCard(),
                          const SizedBox(height: 24),

                          if (permissions.isAdmin) ...[
                            _buildAdminPanelCard(),
                            const SizedBox(height: 24),
                            _buildInviteCard(),
                            const SizedBox(height: 24),
                          ],

                          if (permissions.isFaculty) ...[
                            _buildFacultyPrepCard(),
                            const SizedBox(height: 24),
                          ],

                          if (!permissions.isAdmin &&
                              !permissions.isFaculty) ...[
                            _buildStudentAttendanceCard(),
                            const SizedBox(height: 24),
                            _buildStudyPlanCard(),
                            const SizedBox(height: 24),
                          ],

                          _buildVirtualTourCard(),
                          const SizedBox(height: 24),

                          // Upcoming Reminders
                          _buildRemindersCard(),
                          const SizedBox(height: 32),

                          // Campus Notices
                          const Text(
                            'Campus Notices',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEventsSection(),
                          const SizedBox(
                              height:
                                  96), // Extra bottom padding for floating nav/FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAdminPanelCard() {
    return GestureDetector(
      onTap: () => context.go('/app/admin/users'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.redAccent.withOpacity(0.2),
              Colors.redAccent.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Users',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faculty, Students & Admins',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPlanCard() {
    return GestureDetector(
      onTap: () => context.go('/app/study-planner'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primaryLight, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Planner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-generated schedule ready',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVirtualTourCard() {
    return GestureDetector(
      onTap: () => context.go('/app/virtual-tour'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.secondaryColor.withOpacity(0.2),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vrpano_rounded,
                    color: AppTheme.secondaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '360° Virtual Tour',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore campus in 3D',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextClassCard() {
    final nextClass = _dashboardData?['nextClass'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    nextClass != null ? 'UP NEXT' : 'SCHEDULE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded,
                      color: Colors.white.withOpacity(0.5)),
                  onPressed: () => context.go('/app/timetable'),
                  tooltip: 'View Timetable',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (nextClass != null) ...[
              Text(
                nextClass['course_code'] ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextClass['course_name'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildInfoChip(Icons.access_time_rounded,
                      DateFormatter.formatTime(nextClass['start_time'] ?? '')),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.location_on_rounded,
                      nextClass['location'] ?? 'Unknown'),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.celebration_rounded,
                          size: 48, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No more classes today!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    final reminders = _dashboardData?['reminders'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks Due',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reminders.length} Pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No pending tasks. You\'re all caught up!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              )
            else
              ...reminders.take(3).map((reminder) {
                Color categoryColor;
                switch (reminder['category']) {
                  case 'Exam':
                    categoryColor = AppTheme.errorColor;
                    break;
                  case 'Assignment':
                    categoryColor = AppTheme.warningColor; // Orange
                    break;
                  case 'Project':
                    categoryColor = AppTheme.primaryColor; // Indigo
                    break;
                  default:
                    categoryColor = AppTheme.successColor; // Green
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.5),
                                blurRadius: 6,
                              )
                            ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          reminder['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDate(
                            DateTime.parse(reminder['due_at'])),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/app/reminders'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View All Tasks',
                    style: TextStyle(color: AppTheme.primaryLight)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    final events = _dashboardData?['events'] as List? ?? [];

    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'No recent notices.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppTheme.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['category'] ?? 'General',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            DateFormatter.formatDate(
                              DateTime.parse(event['created_at']),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFacultyPrepCard() {
    return GestureDetector(
      onTap: () => context.go('/app/faculty/daily-prep'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.co_present_rounded,
                    color: AppTheme.primaryLight, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Lecture Co-Pilot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate daily lesson plans instantly',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return GestureDetector(
      onTap: _showInvitationManager,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purpleAccent.withOpacity(0.2),
              Colors.purpleAccent.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Colors.purpleAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate & manage access codes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard() {
    final attendanceStr = _dashboardData?['attendancePercentage']?.toString();
    final percentage = double.tryParse(attendanceStr ?? '') ?? -1.0;

    Color statusColor = Colors.white54;
    Color bgColor = Colors.white.withOpacity(0.05);

    if (percentage >= 0) {
      if (percentage < 75) {
        statusColor = AppTheme.errorColor;
        bgColor = AppTheme.errorColor.withOpacity(0.1);
      } else if (percentage < 85) {
        statusColor = AppTheme.warningColor;
        bgColor = AppTheme.warningColor.withOpacity(0.1);
      } else {
        statusColor = AppTheme.successColor;
        bgColor = AppTheme.successColor.withOpacity(0.1);
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View full subject breakdown',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percentage >= 0 ? percentage / 100 : 0,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: statusColor,
                        strokeWidth: 6,
                      ),
                      Center(
                        child: Text(
                          percentage >= 0 ? '${percentage.toInt()}%' : 'N/A',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/app/student/attendance'),
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: const Text('View Detailed Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvitationManager() {
    showDialog(
      context: context,
      builder: (context) => const InvitationManagerDialog(),
    );
  }
}

class InvitationManagerDialog extends StatefulWidget {
  const InvitationManagerDialog({super.key});

  @override
  State<InvitationManagerDialog> createState() =>
      _InvitationManagerDialogState();
}

class _InvitationManagerDialogState extends State<InvitationManagerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Generate Tab State
  String _selectedRole = 'faculty';
  bool _isBulk = false;
  final TextEditingController _limitController =
      TextEditingController(text: '50');
  String? _generatedCode;

  // List Tab State
  List<Map<String, dynamic>> _invites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    try {
      final data = await _apiService.get(AppConstants.invListEndpoint);
      if (mounted) {
        setState(() {
          _invites = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading invites: $e');
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.post(AppConstants.invGenerateEndpoint, {
        'role': _selectedRole,
        'usage_limit': _isBulk ? int.tryParse(_limitController.text) ?? 1 : 1,
      });

      if (mounted) {
        setState(() {
          _generatedCode = data['code'];
          _isLoading = false;
        });
        _loadInvites(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvite(String code) async {
    final confirmed = await _confirmDelete(code);
    if (confirmed != true) return;

    try {
      await _apiService.delete('${AppConstants.invDeleteEndpoint}/$code');
      _loadInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(String code) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    size: 32, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Invitation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete code\n$code?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1E2E).withOpacity(0.85),
                  const Color(0xFF2D2D44).withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (Glassmorphic)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigoAccent.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            color: Colors.indigoAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Invitation Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs (Custom Styled)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.indigoAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigoAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Generate New'),
                      Tab(text: 'Active Codes'),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGenerateTab(),
                      _buildListTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Selection
          const Text('Role',
              style: TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                dropdownColor: const Color(0xFF2D2D44),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: [
                  DropdownMenuItem(
                    value: 'faculty',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 16, color: Colors.blueAccent),
                        ),
                        const SizedBox(width: 12),
                        const Text('Faculty'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              size: 16, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 12),
                        const Text('Administrator'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bulk Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SwitchListTile(
              title: const Text('Bulk Invitation',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Allow multiple users to use this code',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _isBulk,
              activeColor: AppTheme.primaryColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onChanged: (val) => setState(() => _isBulk = val),
            ),
          ),

          if (_isBulk) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Usage Limit',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                prefixIcon: const Icon(Icons.people_alt_rounded,
                    color: Colors.white54, size: 20),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('GENERATE CODE',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0)),
              ),
            ),
          ),

          if (_generatedCode != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_rounded,
                          size: 16,
                          color: AppTheme.primaryLight.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text('INVITATION CODE',
                          style: TextStyle(
                              color: AppTheme.primaryLight.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _generatedCode!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: Colors.white70),
                          tooltip: 'Copy Code',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _generatedCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListTab() {
    if (_invites.isEmpty) {
      return const Center(
        child: Text('No active invitations.',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invites.length,
      itemBuilder: (context, index) {
        final invite = _invites[index];
        final usageLimit = invite['usage_limit'] ?? 1;
        final isBulk = usageLimit > 1;
        final usedCount = invite['used_count'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  invite['code'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 18, color: Colors.white38),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite['code']));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')));
                  },
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: invite['role'] == 'admin'
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: invite['role'] == 'admin'
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.blueAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            invite['role'] == 'admin'
                                ? Icons.admin_panel_settings_rounded
                                : Icons.school_rounded,
                            size: 12,
                            color: invite['role'] == 'admin'
                                ? Colors.redAccent
                                : Colors.blueAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invite['role'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: invite['role'] == 'admin'
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Type Badge (Bulk/Single)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBulk
                            ? Colors.purpleAccent.withOpacity(0.2)
                            : Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBulk
                              ? Colors.purpleAccent.withOpacity(0.3)
                              : Colors.greenAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isBulk ? 'BULK' : 'SINGLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              isBulk ? Colors.purpleAccent : Colors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$usedCount / $usageLimit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'USED',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  tooltip: 'Revoke Code',
                  onPressed: () => _deleteInvite(invite['code']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
