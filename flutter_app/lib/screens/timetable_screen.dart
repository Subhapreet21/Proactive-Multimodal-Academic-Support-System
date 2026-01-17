import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/permissions.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _entries = [];
  bool _isLoading = true;

  // View State
  String _selectedView = 'Day'; // 'Day' or 'Week'
  String _selectedDay = 'Monday';

  // Filter State
  String _dept = 'CSE';
  String _year = '1';
  String _section = 'A';

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Auto-select current day if valid, else Monday
    final currentDay = _days.contains(getDayName(now.weekday))
        ? getDayName(now.weekday)
        : 'Monday';
    _selectedDay = currentDay;

    _initializeFilters();
    _loadTimetable();
  }

  String getDayName(int weekday) {
    const map = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday'
    };
    return map[weekday] ?? 'Monday';
  }

  void _initializeFilters() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final permissions = AppPermissions(authProvider);

    if (user != null) {
      if (permissions.isStudent) {
        setState(() {
          _dept = user.department ?? 'CSE';
          _year = user.year ?? '1';
          _section = user.section ?? 'A';
        });
      } else if (permissions.isDepartmentLocked) {
        setState(() {
          _dept = user.department ?? 'CSE';
        });
      }
    }
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        AppConstants.timetableEndpoint,
        params: {'department': _dept, 'year': _year, 'section': _section},
      );
      setState(() {
        _entries = response as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timetable: $e')),
        );
      }
    }
  }

  // ... (CRUD Methods: _showAddEditClassDialog, _confirmDelete - Retained logic, updated UI maybe?)
  // For brevity, I will include the logic but wrapped in polished functions.
  Future<void> _showAddEditClassDialog({Map<String, dynamic>? entry}) async {
    final isEdit = entry != null;
    final codeController = TextEditingController(text: entry?['course_code']);
    final nameController = TextEditingController(text: entry?['course_name']);
    final locController = TextEditingController(text: entry?['location']);
    String day = entry?['day_of_week'] ?? _selectedDay;

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    if (isEdit) {
      try {
        final start = entry['start_time'].toString().split(':');
        final end = entry['end_time'].toString().split(':');
        startTime =
            TimeOfDay(hour: int.parse(start[0]), minute: int.parse(start[1]));
        endTime = TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1]));
      } catch (e) {}
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Class' : 'Add New Class',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogField(codeController, 'Course Code',
                      icon: Icons.qr_code_rounded),
                  const SizedBox(height: 16),
                  _buildDialogField(nameController, 'Course Name',
                      icon: Icons.book_rounded),
                  const SizedBox(height: 16),
                  _buildDialogField(locController, 'Location',
                      icon: Icons.location_on_rounded),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: day,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          items: _days
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => day = val!),
                          decoration: _dialogInputDeco('Day').copyWith(
                              prefixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white70,
                                  size: 20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(context, 'Start', startTime,
                            setDialogState, (t) => startTime = t),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(context, 'End', endTime,
                            setDialogState, (t) => endTime = t),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white70),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (codeController.text.isEmpty ||
                              nameController.text.isEmpty) {
                            return;
                          }
                          try {
                            final data = {
                              'course_code': codeController.text,
                              'course_name': nameController.text,
                              'location': locController.text,
                              'day_of_week': day,
                              'start_time':
                                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                              'end_time':
                                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              'department': _dept,
                              'year': _year,
                              'section': _section,
                            };

                            if (isEdit) {
                              await _apiService.put(
                                  '${AppConstants.timetableEndpoint}/${entry['id']}',
                                  data);
                            } else {
                              await _apiService.post(
                                  AppConstants.timetableEndpoint, data);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadTimetable();
                            }
                          } catch (e) {
                            // handle error
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Save Class',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TimeOfDay time,
      StateSetter setState, Function(TimeOfDay) onTimeChanged) {
    return GestureDetector(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: time);
        if (picked != null) {
          setState(() => onTimeChanged(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: AppTheme.primaryLight, size: 16),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dialogInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label,
      {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white.withOpacity(0.7), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    // Similar confirmation logic
    final confirm = await showDialog<bool>(
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
                'Delete Class',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this class?',
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
    if (confirm == true) {
      await _apiService.delete('${AppConstants.timetableEndpoint}/$id');
      _loadTimetable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final permissions = AppPermissions(authProvider);
    final canManage = permissions.canManageTimetable;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Allow gradient from shell or container
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showAddEditClassDialog(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(permissions),
              const SizedBox(height: 16),
              if (_selectedView == 'Day') _buildDaySelector(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedView == 'Day'
                        ? _buildDayView(canManage)
                        : _buildWeekView(canManage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPermissions permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Ensure space between
        children: [
          // Left: View Toggle (Day/Week)
          _buildViewToggle(),

          // Right: Filter Badge (or empty if can't filter)
          if (permissions.canFilterTimetable)
            GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: AppTheme.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$_dept-$_year-$_section',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userRole?.toLowerCase();
    // Logic: Admin can change Dept. Faculty and Student cannot.
    // However, Faculty CAN change year/section. Student cannot change anything (so they shouldn't even see this dialog really, but if they do, lock it).
    // Actually, per requirements: "for the faculty role, the filter should be limited to the department whereas the class and section can be changed."
    final canChangeDept = userRole == 'admin';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Timetable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDialogDropdown(
                  label: 'Department',
                  value: _dept,
                  items: AppConstants.departments,
                  isEnabled: canChangeDept,
                  onChanged: (val) => setDialogState(() => _dept = val!),
                  icon: Icons.business_rounded,
                ),
                const SizedBox(height: 16),
                _buildDialogDropdown(
                  label: 'Year',
                  value: _year,
                  items: AppConstants.years,
                  isEnabled: true, // Faculty and Admin can change
                  onChanged: (val) => setDialogState(() => _year = val!),
                  icon: Icons.school_rounded,
                  itemLabelBuilder: (e) => 'Year $e',
                ),
                const SizedBox(height: 16),
                _buildDialogDropdown(
                  label: 'Section',
                  value: _section,
                  items: AppConstants.sections,
                  isEnabled: true, // Faculty and Admin can change
                  onChanged: (val) => setDialogState(() => _section = val!),
                  icon: Icons.grid_view_rounded,
                  itemLabelBuilder: (e) => 'Section $e',
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadTimetable();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isEnabled = true,
    IconData? icon,
    String Function(String)? itemLabelBuilder,
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
                      if (icon != null) ...[
                        Icon(icon,
                            size: 18,
                            color: isEnabled
                                ? AppTheme.primaryLight
                                : Colors.white24),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        itemLabelBuilder != null ? itemLabelBuilder(e) : e,
                        style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.white54),
                      ),
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

  Widget _buildViewToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildToggleButton('Day', _selectedView == 'Day'),
          _buildToggleButton('Week', _selectedView == 'Week'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedView = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  day.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayView(bool canManage) {
    final dayEntries =
        _entries.where((e) => e['day_of_week'] == _selectedDay).toList();

    // Sort by start_time
    dayEntries.sort((a, b) =>
        (a['start_time'] as String).compareTo(b['start_time'] as String));

    if (dayEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.weekend, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No classes on $_selectedDay',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: dayEntries.length,
      itemBuilder: (context, index) {
        return _buildClassCard(dayEntries[index], canManage, isCompact: false);
      },
    );
  }

  Widget _buildWeekView(bool canManage) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final dayEntries =
            _entries.where((e) => e['day_of_week'] == day).toList();
        dayEntries.sort((a, b) =>
            (a['start_time'] as String).compareTo(b['start_time'] as String));

        return Container(
          width: 280, // Fixed width for each day column
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayEntries.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: dayEntries.isEmpty
                    ? Center(
                        child: Text(
                          'Free',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: dayEntries.length,
                        itemBuilder: (context, i) => _buildClassCard(
                            dayEntries[i], canManage,
                            isCompact: true),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassCard(dynamic entry, bool canManage,
      {required bool isCompact}) {
    // Generate a color based on course code hash or similar for visual variety
    // For now, use a consistent glass style
    final timeStr = '${entry['start_time']} - ${entry['end_time']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6), // Glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['course_name'],
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry['course_code'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF1E293B),
                  onSelected: (val) {
                    if (val == 'edit') _showAddEditClassDialog(entry: entry);
                    if (val == 'delete') _confirmDelete(entry['id']);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit',
                            style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppTheme.errorColor))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                entry['location'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
