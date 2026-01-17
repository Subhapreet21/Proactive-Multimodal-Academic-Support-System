import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

class OnboardingDetailsScreen extends StatefulWidget {
  final String role;
  const OnboardingDetailsScreen({super.key, required this.role});

  @override
  State<OnboardingDetailsScreen> createState() =>
      _OnboardingDetailsScreenState();
}

class _OnboardingDetailsScreenState extends State<OnboardingDetailsScreen> {
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedSection;
  final _accessCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate based on role
    // Validate based on role
    if (widget.role == AppConstants.roleStudent ||
        widget.role == AppConstants.roleFaculty) {
      if (_selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Department'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      if (widget.role == AppConstants.roleStudent &&
          (_selectedYear == null || _selectedSection == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Year and Section'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    } else {
      if (_accessCodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter access code'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.completeOnboarding(
      role: widget.role,
      department: _selectedDepartment,
      year: _selectedYear,
      section: _selectedSection,
      accessCode: _accessCodeController.text.isNotEmpty
          ? _accessCodeController.text
          : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup complete! Please login to continue.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      // Short delay to let user see the message? Or just go.
      // GoRouter transition is usually instant.
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go('/login');
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Onboarding failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.role == AppConstants.roleFaculty
        ? 'Faculty Member'
        : widget.role == AppConstants.roleAdmin
            ? 'Administrator'
            : 'Student';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Setup as $roleName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF1E1B4B), // Indigo 950
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Hero(
                          tag: 'onboarding_step',
                          child: Icon(
                            Icons.fact_check_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Final Steps',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please provide your academic details to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (widget.role == AppConstants.roleStudent ||
                            widget.role == AppConstants.roleFaculty) ...[
                          _buildDropdown(
                            label: 'Department',
                            icon: Icons.business_rounded,
                            value: _selectedDepartment,
                            items: AppConstants.departments,
                            onChanged: (val) =>
                                setState(() => _selectedDepartment = val),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (widget.role == AppConstants.roleStudent) ...[
                          _buildDropdown(
                            label: 'Academic Year',
                            icon: Icons.calendar_today_rounded,
                            value: _selectedYear,
                            items: AppConstants.years,
                            itemLabelBuilder: (val) => 'Year $val',
                            onChanged: (val) =>
                                setState(() => _selectedYear = val),
                          ),
                          const SizedBox(height: 20),
                          _buildDropdown(
                            label: 'Section',
                            icon: Icons.group_rounded,
                            value: _selectedSection,
                            items: AppConstants.sections,
                            itemLabelBuilder: (val) => 'Section $val',
                            onChanged: (val) =>
                                setState(() => _selectedSection = val),
                          ),
                        ],
                        if (widget.role != AppConstants.roleStudent) ...[
                          TextField(
                            controller: _accessCodeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Authentication Code',
                              labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7)),
                              prefixIcon: const Icon(Icons.lock_person_rounded,
                                  color: Colors.white70),
                              hintText: 'Enter code provided by admin',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4)),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryColor),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppTheme.warningColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppTheme.warningColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This code verifies your identity as a member of staff.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Finish Setup',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? itemLabelBuilder,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B), // Dark slate for dropdown menu
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(itemLabelBuilder != null ? itemLabelBuilder(item) : item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
