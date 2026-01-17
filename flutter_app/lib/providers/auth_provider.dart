import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  bool _isPasswordRecovery = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isOnboarded => _user?.isOnboarded ?? false;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get error => _error;
  String? get userRole => _user?.role;

  AuthProvider() {
    _init();
  }

  void _init() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        notifyListeners();
      } else if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
        // Let _checkAuthStatus handle the user reload usually,
        // but we can trigger a notify if needed.
        // For now, just resetting recovery flag.
        notifyListeners();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        // Try to fetch user profile
        _user = await _authService.getProfile();
      }
    } catch (e) {
      print('Auth check error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign In with Email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user =
          await _authService.signInWithEmail(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign Up with Email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify Recovery OTP
  Future<bool> verifyOtp(String email, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyRecoveryOtp(email, token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete onboarding
  Future<bool> completeOnboarding({
    required String role,
    String? department,
    String? year,
    String? section,
    String? accessCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.completeOnboarding(
        role: role,
        department: department,
        year: year,
        section: section,
        accessCode: accessCode,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh profile: $e');
    }
  }

  // Reset Profile (Dev)
  Future<void> resetProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetProfile();
      await refreshProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // Get auth token for API calls
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  // Google Sign-In
  Future<bool> signInWithGoogle({required bool isLoginMode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user =
          await _authService.signInWithGoogle(isLoginMode: isLoginMode);
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw 'Google Sign-In canceled';
      }
    } catch (e) {
      _error = e.toString().replaceAll('AuthException:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
