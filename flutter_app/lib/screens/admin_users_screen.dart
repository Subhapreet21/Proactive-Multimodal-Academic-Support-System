import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // For BackdropFilter

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _users = [];
  bool _isLoading = true;
  String _currentFilter = 'All';
  String? _filterDept;
  String? _filterYear;
  String? _filterSection;
  bool _isSelectionMode = false;
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    // Lock to Portrait Mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchUsers();
  }

  @override
  void dispose() {
    // Reset Orientations (Revert to Global Portrait Default)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      if (_isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectedUserIds.clear();
        });
      }
      String filter;
      switch (_tabController.index) {
        case 1:
          filter = 'student';
          break;
        case 2:
          filter = 'faculty';
          break;
        case 3:
          filter = 'admin';
          break;
        default:
          filter = 'All';
      }
      setState(() {
        _currentFilter = filter;
        _isLoading = true;
        // Optionally clear specific filters when switching main tabs?
        // _filterDept = null;
        // _filterYear = null;
        // _filterSection = null;
      });
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final queryParams = <String, String>{};
      if (_currentFilter != 'All') {
        queryParams['role'] = _currentFilter;
      }
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (_filterDept != null) queryParams['department'] = _filterDept!;
      if (_filterYear != null) queryParams['year'] = _filterYear!;
      if (_filterSection != null) queryParams['section'] = _filterSection!;

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint =
          '/api/admin/users${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await _apiService.get(endpoint);

      if (mounted) {
        setState(() {
          _users = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedUserIds.clear();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        if (_selectedUserIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedUserIds.length == _users.length) {
        _selectedUserIds.clear(); // Toggle off if all selected
      } else {
        for (var u in _users) {
          if (u['id'] != null) _selectedUserIds.add(u['id']);
        }
      }
    });
  }

  Future<void> _performBulkAction(String action,
      [Map<String, dynamic>? updates, bool preserveData = false]) async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.post('/api/admin/users/bulk-update', {
        'userIds': _selectedUserIds.toList(),
        'action': action,
        if (updates != null) 'updates': updates,
        'preserveData': preserveData,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Bulk ${action == 'delete' ? 'deletion' : 'update'} successful')),
      );

      setState(() {
        _isSelectionMode = false;
        _selectedUserIds.clear();
      });
      _fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk action failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    String? tempDept = _filterDept;
    String? tempYear = _filterYear;
    String? tempSection = _filterSection;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.filter_list_rounded,
                            size: 32, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filter Users',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customize your user list view',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Department Filter
                      DropdownButtonFormField<String>(
                        initialValue: tempDept,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Department',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: tempDept != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white54, size: 20),
                                  onPressed: () =>
                                      setDialogState(() => tempDept = null),
                                )
                              : null,
                        ),
                        items: AppConstants.departments
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.business_rounded,
                                          size: 18, color: Colors.white70),
                                      const SizedBox(width: 12),
                                      Text(d),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => tempDept = val),
                      ),
                      const SizedBox(height: 16),

                      // Year Filter
                      DropdownButtonFormField<String>(
                        initialValue: tempYear,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: tempYear != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white54, size: 20),
                                  onPressed: () =>
                                      setDialogState(() => tempYear = null),
                                )
                              : null,
                        ),
                        items: AppConstants.years
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 18, color: Colors.white70),
                                      const SizedBox(width: 12),
                                      Text('Year $y'),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => tempYear = val),
                      ),
                      const SizedBox(height: 16),

                      // Section Filter
                      DropdownButtonFormField<String>(
                        initialValue: tempSection,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Section',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: tempSection != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white54, size: 20),
                                  onPressed: () =>
                                      setDialogState(() => tempSection = null),
                                )
                              : null,
                        ),
                        items: AppConstants.sections
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.class_rounded,
                                          size: 18, color: Colors.white70),
                                      const SizedBox(width: 12),
                                      Text('Sec $s'),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => tempSection = val),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                setState(() {
                                  _filterDept = tempDept;
                                  _filterYear = tempYear;
                                  _filterSection = tempSection;
                                  _isLoading = true;
                                });
                                setState(() {
                                  _filterDept = tempDept;
                                  _filterYear = tempYear;
                                  _filterSection = tempSection;
                                });
                                _fetchUsers();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Apply',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      // Clear All Button
                      if (tempDept != null ||
                          tempYear != null ||
                          tempSection != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: () {
                              setDialogState(() {
                                tempDept = null;
                                tempYear = null;
                                tempSection = null;
                              });
                            },
                            child: const Text('Clear All Filters',
                                style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUserDetails(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _apiService.put('/api/admin/users/$userId', updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details updated successfully')),
      );
      _fetchUsers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  Future<void> _showGlassDialog({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return Dialog(
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon container (if provided)
                if (icon != null) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppTheme.primaryColor)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          size: 32, color: iconColor ?? AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Title
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
                // Subtitle (if provided)
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                content,
                const SizedBox(height: 24),
                if (actions != null)
                  Row(
                    children: [
                      Expanded(child: actions[0]),
                      const SizedBox(width: 16),
                      Expanded(child: actions[1]),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    String selectedRole = user['role'] ?? 'student';
    String? selectedDept = user['department'] ?? 'CSE';
    String? selectedYear = user['year']?.toString() ?? '1';
    String? selectedSection = user['section'] ?? 'A';

    // Identify if editing self
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCurrentUser = user['id'] == currentUserId;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return Dialog(
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (innerDialogContext, setInnerDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 32, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Edit User Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCurrentUser
                            ? 'Update your profile details'
                            : 'Update user information and role',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Field (Locked if Current User)
                      if (isCurrentUser)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded,
                                      color: Colors.white70, size: 18),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text('Admin',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.orange
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock,
                                            size: 10, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text('LOCKED',
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          dropdownColor: AppTheme.cardColor,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'student',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_rounded,
                                        size: 18, color: Colors.white70),
                                    SizedBox(width: 12),
                                    Text('Student'),
                                  ],
                                )),
                            DropdownMenuItem(
                                value: 'faculty',
                                child: Row(
                                  children: [
                                    Icon(Icons.school_rounded,
                                        size: 18, color: Colors.white70),
                                    SizedBox(width: 12),
                                    Text('Faculty'),
                                  ],
                                )),
                            DropdownMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings_rounded,
                                        size: 18, color: Colors.white70),
                                    SizedBox(width: 12),
                                    Text('Admin'),
                                  ],
                                )),
                          ],
                          onChanged: (val) {
                            setInnerDialogState(() {
                              selectedRole = val!;
                            });
                          },
                        ),
                      const SizedBox(height: 16),

                      // Department (Hide for Admin)
                      if (selectedRole != 'admin')
                        DropdownButtonFormField<String>(
                          initialValue: selectedDept,
                          dropdownColor: AppTheme.cardColor,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Department',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: AppConstants.departments
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.business_rounded,
                                            size: 18, color: Colors.white70),
                                        const SizedBox(width: 12),
                                        Text(d),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setInnerDialogState(() => selectedDept = val),
                        ),
                      if (selectedRole != 'admin') const SizedBox(height: 16),
                      const SizedBox(height: 16),

                      // Student Fields
                      if (selectedRole == 'student') ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedYear,
                                dropdownColor: AppTheme.cardColor,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Year',
                                  labelStyle: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7)),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: AppConstants.years
                                    .map((y) => DropdownMenuItem(
                                          value: y,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 18,
                                                  color: Colors.white70),
                                              const SizedBox(width: 12),
                                              Text('Year $y'),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) => setInnerDialogState(
                                    () => selectedYear = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedSection,
                                dropdownColor: AppTheme.cardColor,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Section',
                                  labelStyle: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7)),
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: AppConstants.sections
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.class_rounded,
                                                  size: 18,
                                                  color: Colors.white70),
                                              const SizedBox(width: 12),
                                              Text('Sec $s'),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) => setInnerDialogState(
                                    () => selectedSection = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pop(innerDialogContext),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(innerDialogContext);
                                final updates = <String, dynamic>{
                                  'full_name': nameController.text,
                                  'role': selectedRole,
                                };

                                if (selectedRole == 'student') {
                                  updates['department'] = selectedDept;
                                  updates['year'] = selectedYear;
                                  updates['section'] = selectedSection;
                                } else if (selectedRole == 'faculty') {
                                  updates['department'] = selectedDept;
                                  updates['year'] = null;
                                  updates['section'] = null;
                                } else {
                                  // Admin: clear all academic fields
                                  updates['department'] = null;
                                  updates['year'] = null;
                                  updates['section'] = null;
                                }
                                _updateUserDetails(user['id'], updates);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Save',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActionButton(
      IconData icon, String label, VoidCallback onPressed,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isDestructive ? AppTheme.errorColor : Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isDestructive ? AppTheme.errorColor : Colors.white,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showBulkRolePicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                  const Color(0xFF0F172A).withValues(alpha: 0.98)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select New Role',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                for (var role in ['student', 'faculty', 'admin'])
                  if (role != _currentFilter)
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white70),
                      title: Text(role.toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(sheetContext); // Pop the bottom sheet
                        if (role == 'student') {
                          _showConvertToStudentDialog();
                        } else if (role == 'faculty') {
                          _showConvertToFacultyDialog();
                        } else if (role == 'admin') {
                          _showGlassDialog(
                            title: 'Confirm Admin Access',
                            subtitle:
                                'Grant full system control to selected users',
                            icon: Icons.admin_panel_settings_rounded,
                            iconColor: AppTheme.errorColor,
                            content: const Text(
                              'Selected users will have full administrative privileges.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white70))),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _performBulkAction('update', {'role': role});
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor),
                                child: const Text('Grant Access'),
                              ),
                            ],
                          );
                        } else {
                          _performBulkAction('update', {'role': role});
                        }
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Unified Dialog for Modifying Students (All fields at once)
  void _showBulkModifyDialog() {
    String? selectedDept;
    String? selectedYear;
    String? selectedSection;

    _showGlassDialog(
      title: 'Bulk Modify Students',
      subtitle: 'Update department, year, and section for selected students',
      icon: Icons.edit_rounded,
      iconColor: AppTheme.primaryColor,
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Leave fields empty to keep current values.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Department
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AppConstants.departments
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text(d),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedDept = val),
              ),
              const SizedBox(height: 12),
              // Year
              DropdownButtonFormField<String>(
                initialValue: selectedYear,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['1', '2', '3', '4']
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text('Year $y'),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedYear = val),
              ),
              const SizedBox(height: 12),
              // Section
              DropdownButtonFormField<String>(
                initialValue: selectedSection,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Section',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AppConstants.sections
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              const Icon(Icons.class_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text('Sec $s'),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedSection = val),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: () {
            final updates = <String, dynamic>{};
            if (selectedDept != null) updates['department'] = selectedDept;
            if (selectedYear != null) updates['year'] = selectedYear;
            if (selectedSection != null) updates['section'] = selectedSection;

            if (updates.isNotEmpty) {
              Navigator.pop(context);
              _performBulkAction('update', updates);
            } else {
              Navigator.pop(context);
            }
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Update'),
        ),
      ],
    );
  }

  // Dialog for Converting to Student (Requires Dept/Year/Section)
  void _showConvertToStudentDialog() {
    String selectedDept = 'CSE';
    String selectedYear = '1';
    String selectedSection = 'A';

    _showGlassDialog(
      title: 'Convert to Student',
      subtitle: 'Assign academic details to selected users',
      icon: Icons.school_rounded,
      iconColor: AppTheme.primaryColor,
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade300, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Knowledge base articles will be preserved',
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Dept
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AppConstants.departments
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text(d),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedDept = val!),
              ),
              const SizedBox(height: 12),
              // Year
              DropdownButtonFormField<String>(
                initialValue: selectedYear,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['1', '2', '3', '4']
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text('Year $y'),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedYear = val!),
              ),
              const SizedBox(height: 12),
              // Section
              DropdownButtonFormField<String>(
                initialValue: selectedSection,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Section',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AppConstants.sections
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              const Icon(Icons.class_rounded,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text('Sec $s'),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedSection = val!),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _performBulkAction('update', {
              'role': 'student',
              'department': selectedDept,
              'year': selectedYear,
              'section': selectedSection
            });
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Convert'),
        )
      ],
    );
  }

  void _showBulkDepartmentDialog() {
    String selectedDept = 'CSE';

    _showGlassDialog(
      title: 'Bulk Change Department',
      subtitle: 'Assign a new department to selected users',
      icon: Icons.business_rounded,
      iconColor: AppTheme.primaryColor,
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return DropdownButtonFormField<String>(
            initialValue: selectedDept,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New Department',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: AppConstants.departments
                .map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Row(
                        children: [
                          const Icon(Icons.business_rounded,
                              size: 18, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(dept),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (val) => setDialogState(() => selectedDept = val!),
          );
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _performBulkAction('update', {'department': selectedDept});
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Update'),
        ),
      ],
    );
  }

  // Dialog for Converting to Faculty (Requires Dept)
  void _showConvertToFacultyDialog() {
    String selectedDept = 'CSE';

    _showGlassDialog(
      title: 'Convert to Faculty',
      subtitle: 'Assign teaching department to selected users',
      icon: Icons.school_rounded,
      iconColor: AppTheme.primaryColor,
      content: StatefulBuilder(builder: (dialogContext, setDialogState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Knowledge base articles will be preserved',
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedDept,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Department',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: AppConstants.departments
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Row(
                          children: [
                            const Icon(Icons.business_rounded,
                                size: 18, color: Colors.white70),
                            const SizedBox(width: 12),
                            Text(d),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setDialogState(() => selectedDept = val!),
            ),
          ],
        );
      }),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _performBulkAction('update', {
              'role': 'faculty',
              'department': selectedDept,
              'year': null,
              'section': null,
            });
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Convert'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 Enforce Portrait Mode (Strict Fallback)
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_rounded,
                  color: Colors.white70, size: 64),
              SizedBox(height: 24),
              Text(
                'Please Rotate Your Device',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This page is optimized for portrait mode only.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleSelectionMode,
                ),
                title: Text('${_selectedUserIds.length} Selected',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.select_all, color: Colors.white),
                    label: const Text('Select All',
                        style: TextStyle(color: Colors.white)),
                    onPressed: _selectAll,
                  ),
                ],
              )
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.go('/app/dashboard'),
                ),
                centerTitle: true,
                title: const Text('User Management',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: TabBar(
                      controller: _tabController,
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
                        Tab(text: 'All'),
                        Tab(text: 'Student'),
                        Tab(text: 'Faculty'),
                        Tab(text: 'Admin'),
                      ],
                    ),
                  ),
                ),
              ),
        body: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                // Search and Filter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search users...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4)),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Colors.white54),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          color: Colors.white54),
                                      onPressed: () {
                                        _searchController.clear();
                                        _fetchUsers();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (_) => _fetchUsers(),
                            onChanged: (val) {
                              // Optional: Live search
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      if (_currentFilter != 'admin')
                        Container(
                          decoration: BoxDecoration(
                            color: (_filterDept != null ||
                                    _filterYear != null ||
                                    _filterSection != null)
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (_filterDept != null ||
                                      _filterYear != null ||
                                      _filterSection != null)
                                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: (_filterDept != null ||
                                      _filterYear != null ||
                                      _filterSection != null)
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                            onPressed: _showFilterDialog,
                            tooltip: 'Filter Users',
                          ),
                        ),
                    ],
                  ),
                ),

                // User List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search_rounded,
                                      size: 64,
                                      color:
                                          Colors.white.withValues(alpha: 0.2)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No users found',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _users.length,
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                _isSelectionMode
                                    ? 100
                                    : 16, // Extra padding when selection mode active
                              ),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final role = user['role'] ?? 'student';
                                final currentUserId = Supabase
                                    .instance.client.auth.currentUser?.id;
                                final isCurrentUser =
                                    user['id'] == currentUserId;

                                Color roleColor = AppTheme.primaryLight;
                                Color roleBg = AppTheme.primaryColor
                                    .withValues(alpha: 0.1);

                                if (role == 'admin') {
                                  roleColor = AppTheme.errorColor;
                                  roleBg = AppTheme.errorColor
                                      .withValues(alpha: 0.1);
                                } else if (role == 'faculty') {
                                  roleColor = AppTheme.warningColor;
                                  roleBg = AppTheme.warningColor
                                      .withValues(alpha: 0.1);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.05)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onLongPress: () {
                                        // Disable selection mode on 'All' tab
                                        if (_currentFilter == 'All') {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Bulk actions are disabled in "All" view to prevent errors. Please select a specific role tab.'),
                                            duration: Duration(seconds: 2),
                                          ));
                                          return;
                                        }

                                        if (isCurrentUser) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'You cannot select your own account for bulk operations.'),
                                            backgroundColor: Colors.orange,
                                            duration: Duration(seconds: 2),
                                          ));
                                          return;
                                        }

                                        if (!_isSelectionMode) {
                                          _toggleSelectionMode();
                                          _toggleUserSelection(user['id']);
                                        }
                                      },
                                      onTap: _isSelectionMode
                                          ? () {
                                              if (isCurrentUser) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  content: Text(
                                                      'You cannot select your own account for bulk operations.'),
                                                  backgroundColor:
                                                      Colors.orange,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ));
                                                return;
                                              }
                                              _toggleUserSelection(user['id']);
                                            }
                                          : () => _showEditUserDialog(user),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode) ...[
                                              if (isCurrentUser)
                                                Container(
                                                  width: 24, // Checkbox width
                                                  height: 24,
                                                  margin: const EdgeInsets.only(
                                                      right: 8),
                                                  child: const Icon(
                                                      Icons.lock_outline,
                                                      size: 16,
                                                      color: Colors.white24),
                                                )
                                              else
                                                Checkbox(
                                                  value: _selectedUserIds
                                                      .contains(user['id']),
                                                  onChanged: (val) =>
                                                      _toggleUserSelection(
                                                          user['id']),
                                                  activeColor:
                                                      AppTheme.primaryColor,
                                                  checkColor: Colors.white,
                                                  side: BorderSide(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.5)),
                                                ),
                                              const SizedBox(width: 8),
                                            ],
                                            // Avatar
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: roleColor.withValues(
                                                        alpha: 0.3),
                                                    width: 2),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor: roleBg,
                                                backgroundImage:
                                                    (user['avatar_url'] !=
                                                                null &&
                                                            user['avatar_url']
                                                                .toString()
                                                                .isNotEmpty)
                                                        ? NetworkImage(
                                                            user['avatar_url'])
                                                        : null,
                                                child: (user['avatar_url'] ==
                                                            null ||
                                                        user['avatar_url']
                                                            .toString()
                                                            .isEmpty)
                                                    ? Text(
                                                        (user['full_name']
                                                                    ?[0] ??
                                                                '?')
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                            color: roleColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user['full_name'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    user['email'] ?? '',
                                                    style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.6),
                                                        fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Role Badge
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: roleBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: roleColor
                                                            .withValues(
                                                                alpha: 0.2)),
                                                  ),
                                                  child: Text(
                                                    role.toUpperCase(),
                                                    style: TextStyle(
                                                        color: roleColor,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 0.5),
                                                  ),
                                                ),
                                                if (isCurrentUser)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 6),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                          color: Colors.orange
                                                              .withValues(
                                                                  alpha: 0.3),
                                                          width: 0.5),
                                                    ),
                                                    child: const Icon(
                                                      Icons.lock_rounded,
                                                      size: 12,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
            // Bottom Action Bar (Glassmorphic)
            if (_isSelectionMode)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        border: Border(
                            top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_currentFilter == 'student')
                            _buildBulkActionButton(
                                Icons.arrow_upward, 'Promote', () {
                              bool hasFinalYear = _users
                                  .where(
                                      (u) => _selectedUserIds.contains(u['id']))
                                  .any((u) => u['year'] == '4');

                              String dialogTitle = 'Promote Students';
                              String dialogContent =
                                  'Promote selected students to the next year?';

                              if (hasFinalYear) {
                                dialogTitle = 'Mixed Year Promotion';
                                dialogContent =
                                    'Some selected students are in Final Year (4).\n\nThey will NOT be promoted further. Others will move up.';
                              }

                              _showGlassDialog(
                                title: dialogTitle,
                                subtitle: hasFinalYear
                                    ? 'Final year students will remain in year 4'
                                    : 'Move students to the next academic year',
                                icon: Icons.arrow_upward_rounded,
                                iconColor: AppTheme.primaryColor,
                                content: Text(dialogContent,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _performBulkAction(
                                          'update', {'year_increment': true});
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor),
                                    child: const Text('Promote'),
                                  ),
                                ],
                              );
                            }),
                          if (_currentFilter == 'student')
                            _buildBulkActionButton(Icons.edit_note, 'Modify',
                                () {
                              _showBulkModifyDialog();
                            }),
                          if (_currentFilter == 'faculty')
                            _buildBulkActionButton(Icons.domain, 'Department',
                                () {
                              _showBulkDepartmentDialog();
                            }),
                          if (_currentFilter == 'faculty' ||
                              _currentFilter == 'admin')
                            _buildBulkActionButton(
                                Icons.manage_accounts, 'Role', () {
                              _showBulkRolePicker();
                            }),
                          _buildBulkActionButton(Icons.delete, 'Delete', () {
                            bool isAdminTab = _currentFilter == 'admin';
                            String dialogContent = _currentFilter == 'admin'
                                ? 'Delete selected ADMINS? Profiles only.'
                                : 'Delete selected ${_currentFilter.toUpperCase()}? All related data removed.';

                            _showGlassDialog(
                              title: 'Delete Users',
                              subtitle: isAdminTab
                                  ? 'Permanently remove admin profiles'
                                  : 'Permanently remove users and all related data',
                              icon: Icons.delete_rounded,
                              iconColor: AppTheme.errorColor,
                              content: Text(dialogContent,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _performBulkAction(
                                        'delete', null, isAdminTab);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorColor),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          }, isDestructive: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
