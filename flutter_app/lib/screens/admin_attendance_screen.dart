import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../config/theme.dart';
import 'admin_manage_attendance_tab.dart';
import 'overall_attendance_tab.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  Map<String, dynamic>? _adminStats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final data = await _attendanceService.getAdminStats();
      if (mounted) {
        setState(() {
          _adminStats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGlobalOverview() {
    final overallPercentage = _adminStats?['overallPercentage'] ?? 0;
    final breakdown = _adminStats?['departmentBreakdown'] as List? ?? [];
    final hasData = breakdown.isNotEmpty;

    Color statusColor = AppTheme.successColor;
    if (!hasData)
      statusColor = Colors.white54;
    else if (overallPercentage < 75)
      statusColor = AppTheme.errorColor;
    else if (overallPercentage < 85) statusColor = AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Institutional Average',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: hasData ? overallPercentage / 100 : 0,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: statusColor,
                  strokeWidth: 12,
                ),
              ),
              Text(
                hasData ? '$overallPercentage%' : 'N/A',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Based on the last 30 days',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBreakdown() {
    final breakdown = _adminStats?['departmentBreakdown'] as List? ?? [];
    final allDepartments = ['CSE', 'ECE', 'EEE', 'ME', 'CE', 'IT'];

    // Map breakdown to include missing ones with N/A
    final List<Map<String, dynamic>> completeBreakdown =
        allDepartments.map((dept) {
      final existing = breakdown.firstWhere((b) => b['department'] == dept,
          orElse: () => null);
      if (existing != null) {
        return Map<String, dynamic>.from(existing);
      }
      return <String, dynamic>{
        'department': dept,
        'percentage': null,
      };
    }).toList();

    // Sort departments by percentage (lowest first, NULL at the bottom)
    completeBreakdown.sort((a, b) {
      if (a['percentage'] == null && b['percentage'] == null) return 0;
      if (a['percentage'] == null) return 1;
      if (b['percentage'] == null) return -1;
      return (a['percentage'] as num).compareTo(b['percentage'] as num);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Department Leaderboard (All Departments)',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...completeBreakdown.map((deptData) {
          final pct = deptData['percentage'];
          final isNA = pct == null;

          Color sColor = AppTheme.successColor;
          if (isNA) {
            sColor = Colors.grey;
          } else if (pct < 75) {
            sColor = AppTheme.errorColor;
          } else if (pct < 85) {
            sColor = AppTheme.warningColor;
          }

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business_rounded, color: sColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deptData['department'] ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: isNA ? 0 : pct / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: sColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  isNA ? 'N/A' : '$pct%',
                  style: TextStyle(
                      color: sColor, fontWeight: FontWeight.bold, fontSize: 16),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Statistics'),
                    Tab(text: 'Overall %'),
                    Tab(text: 'Manage'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Stats
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildGlobalOverview(),
                                const SizedBox(height: 32),
                                _buildDepartmentBreakdown(),
                              ],
                            ),
                          ),
                    // Tab 2: Overall %
                    const OverallAttendanceTab(isFaculty: false),
                    // Tab 3: Manage
                    const AdminManageAttendanceTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
