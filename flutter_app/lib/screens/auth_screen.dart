import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_passwordController.text.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password is required'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    bool success;
    if (_isLogin) {
      success = await authProvider.signInWithEmail(
          email: _emailController.text, password: _passwordController.text);
    } else {
      success = await authProvider.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Redirection handled by router
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Authentication failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.primaryLight),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your email address to receive a password reset code.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Enter your email').copyWith(
                  prefixIcon: Icon(Icons.email_outlined,
                      color: Colors.white.withOpacity(0.4), size: 20),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white60)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty) return;
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        Navigator.pop(dialogContext); // Close first

                        // Show temporary loader or status could be better, but keeping simple flow
                        try {
                          final success = await authProvider
                              .resetPassword(emailController.text);
                          if (mounted) {
                            if (success) {
                              if (context.mounted) {
                                context.push(
                                    '/verify-otp?email=${emailController.text}');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed: ${authProvider.error ?? "Unknown error"}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Handle error
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send Code',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Brand Icon
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
                        Icons.school_rounded,
                        size: 40,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auth Card (Glassmorphism)
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Toggle Switch (LayoutBuilder for correctness)
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      AnimatedAlign(
                                        alignment: _isLogin
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: Container(
                                          width: constraints.maxWidth / 2,
                                          height: constraints.maxHeight,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                  () => _isLogin = true),
                                              behavior: HitTestBehavior.opaque,
                                              child: Center(
                                                child: Text(
                                                  'Log In',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                  () => _isLogin = false),
                                              behavior: HitTestBehavior.opaque,
                                              child: Center(
                                                child: Text(
                                                  'Sign Up',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Header Text
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? 'Enter your credentials to access your account'
                                  : 'Sign up to start your academic journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. Google Button
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final authProvider =
                                          Provider.of<AuthProvider>(context,
                                              listen: false);
                                      setState(() => _isLoading = true);
                                      final success =
                                          await authProvider.signInWithGoogle(
                                              isLoginMode: _isLogin);
                                      setState(() => _isLoading = false);
                                      if (success && mounted) {
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  authProvider.error ??
                                                      'Google Sign-In failed')),
                                        );
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white,
                                side: BorderSide.none,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                    height: 22,
                                    width: 22,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('G',
                                          style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22));
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OR Divider
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.1))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text('or',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 13)),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.1))),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Name Field
                            if (!_isLogin) ...[
                              _buildLabel('Full Name'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration(
                                    'Enter your full name'),
                                validator: (val) =>
                                    val!.isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            _buildLabel('Email address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                  'Enter your email address'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => (!val!.contains('@'))
                                  ? 'Invalid email'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildLabel('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Colors.white),
                              decoration:
                                  _buildInputDecoration('Enter your password')
                                      .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Password is required'
                                  : null,
                            ),

                            const SizedBox(height: 24),

                            // Forgot Password
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(
                                          color: AppTheme.primaryLight,
                                          fontSize: 13)),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Continue Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            _isLogin
                                                ? 'Sign In'
                                                : 'Create Account',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded,
                                            size: 18),
                                      ],
                                    ),
                            ),
                          ],
                        ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
