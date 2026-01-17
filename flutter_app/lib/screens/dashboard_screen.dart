import 'package:flutter/material.dart';
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

    // Removed Scaffold/AppBar to prevent double header.
    // Shell/Parent likely handles the AppBar.
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

                          if (!permissions.isAdmin &&
                              !permissions.isFaculty) ...[
                            _buildStudyPlanCard(),
                            const SizedBox(height: 24),
                          ],

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
}
