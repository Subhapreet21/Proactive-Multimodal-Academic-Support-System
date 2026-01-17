import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedRole;
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
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role first')),
      );
      return;
    }

    // Validate based on role
    if (_selectedRole == AppConstants.roleStudent) {
      if (_selectedDepartment == null || _selectedYear == null || _selectedSection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Department, Year, and Section'),
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
      role: _selectedRole!,
      department: _selectedDepartment,
      year: _selectedYear,
      section: _selectedSection,
      accessCode: _accessCodeController.text.isNotEmpty ? _accessCodeController.text : null,
    );
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      context.go('/app/dashboard');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedRole == null ? 'Choose Your Role' : 'Complete Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _selectedRole == null ? 'Step 1: Select Your Role' : 'Role Selected',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Role Selection
            _buildRoleCard(AppConstants.roleStudent, Icons.school, 'Student'),
            const SizedBox(height: 12),
            _buildRoleCard(AppConstants.roleFaculty, Icons.person, 'Faculty'),
            const SizedBox(height: 12),
            _buildRoleCard(AppConstants.roleAdmin, Icons.admin_panel_settings, 'Admin'),
            const SizedBox(height: 32),
            
            // Student-specific fields
            if (_selectedRole == AppConstants.roleStudent) ...[
              const Text(
                'Your Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                ),
                dropdownColor: AppTheme.surfaceColor,
                items: AppConstants.departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (value) => setState(() => _selectedDepartment = value),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                dropdownColor: AppTheme.surfaceColor,
                items: AppConstants.years.map((year) {
                  return DropdownMenuItem(value: year, child: Text('Year $year'));
                }).toList(),
                onChanged: (value) => setState(() => _selectedYear = value),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedSection,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  prefixIcon: Icon(Icons.group),
                ),
                dropdownColor: AppTheme.surfaceColor,
                items: AppConstants.sections.map((section) {
                  return DropdownMenuItem(value: section, child: Text('Section $section'));
                }).toList(),
                onChanged: (value) => setState(() => _selectedSection = value),
              ),
            ],
            
            // Faculty/Admin access code
            if (_selectedRole == AppConstants.roleFaculty || _selectedRole == AppConstants.roleAdmin) ...[
              const Text(
                'Access Code Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _accessCodeController,
                decoration: const InputDecoration(
                  labelText: 'Access Code',
                  prefixIcon: Icon(Icons.lock),
                  hintText: 'Enter your access code',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: const Text(
                  'Contact your department head for the access code',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            
            if (_selectedRole != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Complete Setup',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoleCard(String role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
