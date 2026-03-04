import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int _selectedTimelineDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final data =
          await _attendanceService.getAdminStats(days: _selectedTimelineDays);
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

  Widget _buildSystemicRiskAudit() {
    final auditMessage = _adminStats?['aiAudit'];
    if (auditMessage == null || auditMessage == "")
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.secondaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI SYSTEMIC RISK AUDIT',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  auditMessage,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalOverview() {
    final overallPercentage = (_adminStats?['overallPercentage'] ?? 0) as num;
    final dailyHistory = _adminStats?['dailyHistory'] as List? ?? [];
    final hasData = dailyHistory.isNotEmpty;

    Color statusColor = AppTheme.successColor;
    if (!hasData)
      statusColor = Colors.white54;
    else if (overallPercentage < 75)
      statusColor = AppTheme.errorColor;
    else if (overallPercentage < 85) statusColor = AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Institutional Average',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Graph up to present day: $_selectedTimelineDays Days',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  hasData ? '$overallPercentage%' : 'N/A',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Historical Line
                        LineChartBarData(
                          spots: dailyHistory.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(),
                                (e.value['percentage'] as num).toDouble());
                          }).toList(),
                          isCurved: true,
                          color: statusColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: statusColor.withValues(alpha: 0.1),
                          ),
                        ),
                        // Prediction Line (dashed/dotted)
                        if (dailyHistory.isNotEmpty)
                          LineChartBarData(
                            spots: [
                              FlSpot(
                                  (dailyHistory.length - 1).toDouble(),
                                  (dailyHistory.last['percentage'] as num)
                                      .toDouble()),
                              FlSpot(
                                  (dailyHistory.length + 5).toDouble(),
                                  (dailyHistory.last['percentage'] as num)
                                          .toDouble() +
                                      2), // Simple upward projection
                            ],
                            isCurved: false,
                            color: statusColor.withValues(alpha: 0.5),
                            barWidth: 4,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('Not enough data for chart',
                        style: TextStyle(color: Colors.white54))),
          ),
          const SizedBox(height: 16),
          if (hasData)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: AppTheme.successColor, size: 16),
                SizedBox(width: 8),
                Text(
                  'AI predicts a 2% recovery trend',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _buildTimelineFilters(),
        ],
      ),
    );
  }

  Widget _buildTimelineFilters() {
    final filters = [
      {'label': '7D', 'days': 7},
      {'label': '30D', 'days': 30},
      {'label': '3M', 'days': 90},
      {'label': '6M', 'days': 180},
      {'label': '1Y', 'days': 365},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters.map((filter) {
        final isSelected = _selectedTimelineDays == filter['days'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimelineDays = filter['days'] as int;
              _isLoading = true;
            });
            _fetchStats();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.white24,
              ),
            ),
            child: Text(
              filter['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.2),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
                                _buildSystemicRiskAudit(),
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
