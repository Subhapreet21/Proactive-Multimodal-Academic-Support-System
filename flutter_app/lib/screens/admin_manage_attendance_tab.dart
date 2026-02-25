import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/attendance_service.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

class AdminManageAttendanceTab extends StatefulWidget {
  const AdminManageAttendanceTab({super.key});

  @override
  State<AdminManageAttendanceTab> createState() =>
      _AdminManageAttendanceTabState();
}

class _AdminManageAttendanceTabState extends State<AdminManageAttendanceTab> {
  final ApiService _apiService = ApiService();
  final AttendanceService _attendanceService = AttendanceService();

  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = 'CSE';
  String _selectedYear = '1';
  String _selectedSection = 'A';

  bool _isLoadingSlots = false;
  List<dynamic> _availableSlots = [];

  // Marking UI State
  bool _isMarkingMode = false;
  Map<String, dynamic>? _activeSlot;
  bool _isLoadingRecords = false;
  bool _isAlreadyMarked = false;
  String _markedBy = '';
  List<dynamic> _studentsToMark = [];

  // Departments List
  final List<String> _departments = ['CSE', 'ECE', 'EEE', 'ME', 'CE', 'IT'];

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _isMarkingMode = false;
    });
    try {
      final dayOfWeek = DateFormat('EEEE').format(_selectedDate);

      // Fetch all timetables for this department, year, section
      final params = {
        'department': _selectedDepartment,
        'year': _selectedYear,
        'section': _selectedSection,
      };

      final response = await _apiService.get(
        AppConstants.timetableEndpoint,
        params: params,
      );

      final List<dynamic> allEntries = response is List ? response : [];

      // Filter slots for the selected day
      setState(() {
        _availableSlots = allEntries.where((e) {
          final day = e['day_of_week'];
          if (day is String) return day == dayOfWeek;
          if (day is List) return day.contains(dayOfWeek);
          return false;
        }).toList();

        // Sort by start_time
        _availableSlots.sort(
            (a, b) => (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _startMarking(Map<String, dynamic> slot) async {
    setState(() {
      _activeSlot = slot;
      _isMarkingMode = true;
      _isLoadingRecords = true;
      _studentsToMark = [];
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _attendanceService.getClassAttendance(
        slot['id'],
        formattedDate,
      );

      setState(() {
        _isAlreadyMarked = response['isMarked'] ?? false;
        _markedBy = response['markedBy'] ?? '';
        _studentsToMark = response['records'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student list: $e')),
        );
        setState(() => _isMarkingMode = false);
      }
    } finally {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  Future<void> _submitAttendance() async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final records = _studentsToMark
          .map((s) => {'student_id': s['student_id'], 'status': s['status']})
          .toList();

      await _attendanceService.markAttendance(
        timetableId: _activeSlot!['id'],
        date: formattedDate,
        records: records,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully!')),
        );
        setState(() => _isMarkingMode = false);

        // Redirect to Attendance Statistics home tab
        DefaultTabController.of(context).animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(), // Can't mark future attendance
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSlots();
    }
  }

  Widget _buildGlassDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required String Function(String) itemLabelBuilder,
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: AppTheme.primaryLight),
                      const SizedBox(width: 12),
                      Text(itemLabelBuilder(e)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.edit_calendar_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextSelector() {
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
          const Text('Filter Classes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildGlassDatePicker(
                  label: 'Date',
                  date: _selectedDate,
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _buildGlassDropdown(
                  label: 'Department',
                  value: _selectedDepartment,
                  items: _departments,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedDepartment = newValue);
                      _fetchSlots();
                    }
                  },
                  icon: Icons.business_rounded,
                  itemLabelBuilder: (val) => val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGlassDropdown(
                  label: 'Year',
                  value: _selectedYear,
                  items: ['1', '2', '3', '4'],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedYear = newValue);
                      _fetchSlots();
                    }
                  },
                  icon: Icons.school_rounded,
                  itemLabelBuilder: (val) => 'Year $val',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassDropdown(
                  label: 'Section',
                  value: _selectedSection,
                  items: ['A', 'B', 'C'],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedSection = newValue);
                      _fetchSlots();
                    }
                  },
                  icon: Icons.grid_view_rounded,
                  itemLabelBuilder: (val) => 'Section $val',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotList() {
    if (_isLoadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No classes found for this criteria.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Select Class to Edit/Manage',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        ..._availableSlots.map((slot) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => _startMarking(slot),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_, color: AppTheme.primaryLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot['course_name'] ?? 'Subject',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            '${slot['start_time']} - ${slot['end_time']}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.white54),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMarkingView() {
    if (_isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isMarkingMode = false),
            ),
            Expanded(
              child: Text(
                '${_activeSlot!['course_name']} Attendance',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_isAlreadyMarked)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.yellow.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.yellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Last modified by Prof. $_markedBy. You are viewing as Admin.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var student in _studentsToMark) {
                    student['status'] = 'present';
                  }
                });
              },
              icon: const Icon(Icons.done_all, color: Colors.greenAccent),
              label: const Text('All Present',
                  style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var student in _studentsToMark) {
                    student['status'] = 'absent';
                  }
                });
              },
              icon: const Icon(Icons.clear_all, color: Colors.redAccent),
              label: const Text('All Absent',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _studentsToMark.length,
            itemBuilder: (context, index) {
              final student = _studentsToMark[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                      backgroundImage: student['avatar_url'] != null
                          ? NetworkImage(student['avatar_url'])
                          : null,
                      child: student['avatar_url'] == null
                          ? Text(student['name']?[0] ?? '?',
                              style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        student['name'] ?? 'Unknown Student',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButton<String>(
                      value: student['status'],
                      dropdownColor: AppTheme.surfaceColor,
                      style: const TextStyle(color: Colors.white),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'present',
                            child: Text('Present',
                                style: TextStyle(color: Colors.greenAccent))),
                        DropdownMenuItem(
                            value: 'absent',
                            child: Text('Absent',
                                style: TextStyle(color: Colors.redAccent))),
                        DropdownMenuItem(
                            value: 'late',
                            child: Text('Late',
                                style: TextStyle(color: Colors.orangeAccent))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          student['status'] = val;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isMarkingMode
          ? _buildMarkingView()
          : Column(
              children: [
                _buildContextSelector(),
                Expanded(child: SingleChildScrollView(child: _buildSlotList())),
              ],
            ),
    );
  }
}
