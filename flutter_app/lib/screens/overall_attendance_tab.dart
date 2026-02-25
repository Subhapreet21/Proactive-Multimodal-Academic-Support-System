import 'package:flutter/material.dart';
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
              CircleAvatar(
                backgroundColor: sColor.withOpacity(0.2),
                child: Text(
                  student['full_name']?.substring(0, 1).toUpperCase() ?? 'S',
                  style: TextStyle(color: sColor, fontWeight: FontWeight.bold),
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
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
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
