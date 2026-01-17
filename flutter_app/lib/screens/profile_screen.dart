import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Replaced Scaffold/AppBar with Container to avoid double header
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A), // Deep Slate
            Color(0xFF1E1B4B), // Indigo-950
            Color(0xFF312E81), // Indigo-900
          ],
        ),
      ),
      child: SafeArea(
        // Changed to Column with Spacer to attempt to fill screen but fit content
        // Using LayoutBuilder to allow scrolling ONLY if screen is too small,
        // but trying to fit usually involves Flexible/Expanded widgets.
        // Since we want "Fit in one page", let's use a Column.
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribute space
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header - Compact
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(3), // Reduced padding
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.5),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40, // Reduced radius 50 -> 40
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.2),
                                backgroundImage: user?.avatarUrl != null
                                    ? NetworkImage(user!.avatarUrl!)
                                    : null,
                                child: user?.avatarUrl == null
                                    ? Text(
                                        user?.fullName
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'U',
                                        style: const TextStyle(
                                          fontSize: 32, // Reduced font size
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.fullName ?? 'User',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22, // Reduced font size
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                (user?.role ?? 'student').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Academic Details - Horizontal Row for Compactness
                      if (user?.role == 'student')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: _buildCompactInfo(
                                      'Department',
                                      user?.department ?? 'N/A',
                                      Icons.school_outlined)),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.1)),
                              Expanded(
                                  child: _buildCompactInfo(
                                      'Year',
                                      user?.year != null
                                          ? '${user?.year}'
                                          : 'N/A',
                                      Icons.calendar_today_outlined)),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.1)),
                              Expanded(
                                  child: _buildCompactInfo(
                                      'Section',
                                      user?.section ?? 'N/A',
                                      Icons.class_outlined)),
                            ],
                          ),
                        ),

                      if (user?.role == 'faculty' || user?.role == 'admin')
                        _buildGlassInfoCard('Department',
                            user?.department ?? 'All', Icons.business_outlined),
                    ],
                  ),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmSignOut(context, authProvider),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Sign Out',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16), // Slightly reduced padding
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, AuthProvider authProvider) async {
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
                child: const Icon(Icons.logout_rounded,
                    size: 32, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
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
                      child: const Text('Sign Out',
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
      await authProvider.signOut();
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  Widget _buildCompactInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInfoCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
