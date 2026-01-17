import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password updated successfully! Please login.')),
          );

          // Sign out the user to force re-login with new password
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.signOut();

          // Small delay to ensure router updates auth state
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            context.go('/auth');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1), width: 1),
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
                          const Text(
                            'Set New Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your new password must be different from previously used passwords.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Password Field
                          Text(
                            'New Password',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _buildInputDecoration('Enter new password')
                                    .copyWith(
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password Field
                          Text(
                            'Confirm Password',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _buildInputDecoration('Confirm new password')
                                    .copyWith(
                              prefixIcon: Icon(Icons.lock_clock_outlined,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 8,
                              shadowColor:
                                  AppTheme.primaryColor.withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text(
                                    'Update Password',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
