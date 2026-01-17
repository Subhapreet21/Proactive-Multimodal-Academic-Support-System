import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who are you?'),
        centerTitle: true,
      ),
// ... (rest of the file remains, jumping to the blur part)

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              // A hint of primary color at the bottom
              Color(0xFF1E1B4B), // Indigo 950
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Select Your Persona',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose how you will engage with the campus community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRoleCard(
                        context,
                        AppConstants.roleStudent,
                        Icons.school_rounded,
                        'Student',
                        'Access timetables, join events, and use AI assistant for your studies.',
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        AppConstants.roleFaculty,
                        Icons.person_pin_rounded,
                        'Faculty Member',
                        'Manage schedules, publish knowledge base articles, and guide students.',
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        AppConstants.roleAdmin,
                        Icons.admin_panel_settings_rounded,
                        'Administrator',
                        'Global management of events, users, and campus-wide notifications.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String role,
    IconData icon,
    String title,
    String description,
  ) {
    return GestureDetector(
      onTap: () {
        context.push('/onboarding-details?role=$role');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
