import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/attendance_service.dart';
import '../config/theme.dart';

class OverallAttendanceTab extends StatefulWidget {
  final bool isFaculty;
  final String? facultyDepartment;

  const OverallAttendanceTab({
    super.key,
    this.isFaculty = false,
    this.facultyDepartment,
  });

  @override
  State<OverallAttendanceTab> createState() => _OverallAttendanceTabState();
}

class _OverallAttendanceTabState extends State<OverallAttendanceTab> {
  final AttendanceService _attendanceService = AttendanceService();

  String _selectedDepartment = 'CSE';
  String _selectedYear = 'All';
  String _selectedSection = 'All';

  bool _isLoading = false;
  List<dynamic> _students = [];

  final List<String> _departments = [
    'All',
    'CSE',
    'ECE',
    'EEE',
    'ME',
    'CE',
    'IT'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isFaculty && widget.facultyDepartment != null) {
      _selectedDepartment = widget.facultyDepartment!;
    }
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final data = await _attendanceService.getFilteredStudents(
        department: _selectedDepartment,
        year: _selectedYear,
        section: _selectedSection,
      );
      if (mounted) {
        setState(() {
          _students = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student attendance: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGlassDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required String Function(String) itemLabelBuilder,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isEnabled ? Colors.white70 : Colors.white24),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: isEnabled
                              ? AppTheme.primaryLight
                              : Colors.white24),
                      const SizedBox(width: 12),
                      Text(itemLabelBuilder(e)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Students',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.isFaculty) ...[
            Text('Department: ${widget.facultyDepartment ?? 'N/A'}',
                style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ] else ...[
            _buildGlassDropdown(
              label: 'Department',
              value: _selectedDepartment,
              items: _departments,
              isEnabled: true,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedDepartment = newValue);
                  _fetchStudents();
                }
              },
              icon: Icons.business_rounded,
              itemLabelBuilder: (val) => val == 'All' ? 'All Departments' : val,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildGlassDropdown(
                  label: 'Year',
                  value: _selectedYear,
                  items: ['All', '1', '2', '3', '4'],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedYear = newValue);
                      _fetchStudents();
                    }
                  },
                  icon: Icons.school_rounded,
                  itemLabelBuilder: (val) =>
                      val == 'All' ? 'All Years' : 'Year $val',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassDropdown(
                  label: 'Section',
                  value: _selectedSection,
                  items: ['All', 'A', 'B', 'C'],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedSection = newValue);
                      _fetchStudents();
                    }
                  },
                  icon: Icons.grid_view_rounded,
                  itemLabelBuilder: (val) =>
                      val == 'All' ? 'All Sections' : 'Section $val',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_students.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No students found for this criteria.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final pct = student['overall_percentage'];

        Color sColor = AppTheme.successColor;
        if (pct < 75) {
          sColor = AppTheme.errorColor;
        } else if (pct < 85) {
          sColor = AppTheme.warningColor;
        }

        return GestureDetector(
          onTap: () => _showStudentDetails(student),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                student['avatar_url'] != null &&
                        student['avatar_url'].toString().isNotEmpty
                    ? Hero(
                        tag: 'avatar_${student['id']}',
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              CachedNetworkImageProvider(student['avatar_url']),
                          backgroundColor: sColor.withOpacity(0.2),
                        ),
                      )
                    : Hero(
                        tag: 'avatar_${student['id']}',
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: sColor.withOpacity(0.2),
                          child: Text(
                            student['full_name']
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'S',
                            style: TextStyle(
                                color: sColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${student['email'] ?? 'N/A'}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: TextStyle(
                          color: sColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student['attended_classes']}/${student['total_classes']} Classes',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStudentDetails(dynamic student) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildStudentDetailsSheet(student),
    );
  }

  Widget _buildStudentDetailsSheet(dynamic student) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    student['avatar_url'] != null &&
                            student['avatar_url'].toString().isNotEmpty
                        ? Hero(
                            tag: 'avatar_${student['id']}',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: CachedNetworkImageProvider(
                                  student['avatar_url']),
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          )
                        : Hero(
                            tag: 'avatar_${student['id']}',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              child: Text(
                                student['full_name']
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'S',
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            student['email'] ?? 'N/A',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${student['overall_percentage']}%',
                        style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _attendanceService.getStudentStats(
                      studentId: student['id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading details.',
                              style: TextStyle(color: AppTheme.errorColor)));
                    }

                    final data = snapshot.data;
                    final breakdown = data?['subjectBreakdown'] as List? ?? [];

                    if (breakdown.isEmpty) {
                      return const Center(
                          child: Text(
                              'No attendance records found for this student.',
                              style: TextStyle(color: Colors.white54)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: breakdown.length,
                      itemBuilder: (context, index) {
                        final subject = breakdown[index];
                        final pct = subject['percentage'] ?? 0;
                        Color sColor = AppTheme.successColor;
                        if (pct < 75)
                          sColor = AppTheme.errorColor;
                        else if (pct < 85) sColor = AppTheme.warningColor;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: sColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: sColor.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.subject_rounded,
                                    color: sColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subject['course'] ?? 'Unknown',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${subject['present']} / ${subject['total']} classes',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: sColor.withOpacity(0.3)),
                                ),
                                child: Text('$pct%',
                                    style: TextStyle(
                                        color: sColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStudents,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            _buildStudentList(),
          ],
        ),
      ),
    );
  }
}
