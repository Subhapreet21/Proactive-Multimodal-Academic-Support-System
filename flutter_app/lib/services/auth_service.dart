import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Store auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.storageKeyToken, value: token);
    _apiService.setAuthToken(token);
  }

  // Get stored token
  Future<String?> getToken() async {
    final token = await _storage.read(key: AppConstants.storageKeyToken);
    if (token != null) {
      _apiService.setAuthToken(token);
    }
    return token;
  }

  // Clear auth token
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.storageKeyToken);
    _apiService.clearAuthToken();
  }

  // Sync user with backend
  Future<UserModel> syncUser({
    required String email,
    required String fullName,
    String? avatarUrl,
  }) async {
    final response = await _apiService.post(
      AppConstants.authSyncEndpoint,
      {
        'email': email,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
      },
    );

    return UserModel.fromJson(response);
  }

  // Complete onboarding
  Future<UserModel> completeOnboarding({
    required String role,
    String? department,
    String? year,
    String? section,
    String? accessCode,
  }) async {
    final body = <String, dynamic>{
      'role': role,
    };

    if (department != null) body['department'] = department;
    if (year != null) body['year'] = year;
    if (section != null) body['section'] = section;
    if (accessCode != null) body['code'] = accessCode;

    final response = await _apiService.post(
      AppConstants.onboardingEndpoint,
      body,
    );

    return UserModel.fromJson(response);
  }

  // Get current user profile
  Future<UserModel> getProfile() async {
    final response = await _apiService.get(AppConstants.profileEndpoint);
    return UserModel.fromJson(response);
  }

  // Logout
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Google Sign-Out Error (Safe to ignore): $e');
    }
    await clearToken();
  }

  // Reset Profile (Dev)
  Future<void> resetProfile() async {
    await _apiService.post(AppConstants.resetProfileEndpoint, {});
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle({required bool isLoginMode}) async {
    try {
      // 1. Web-based OAuth (works on Android too if deep links configured)
      // For strictly native Google Sign In, we use google_sign_in package
      final clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      print(
          '🔍 [AuthService] Using Web Client ID: ${clientId?.substring(0, 5)}...');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: clientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      final accessToken = googleAuth?.accessToken;
      final idToken = googleAuth?.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final session = response.session;
      if (session == null) return null;

      final token = session.accessToken;
      await saveToken(token);

      // Sync with our backend
      final user = await syncUser(
        email: session.user.email ?? '',
        fullName: session.user.userMetadata?['full_name'] ?? 'Google User',
        avatarUrl: session.user.userMetadata?['avatar_url'],
      );

      // Check Intent vs Reality
      if (isLoginMode) {
        // LOGIN MODE: User must exist
        if (user.isNewUser) {
          // We just created a new profile for them -> Not allowed in Login Web
          print('❌ [AuthService] New user tried to Login. Blocking.');
          await logout();
          throw 'Account not found. Please Sign Up.';
        }
      } else {
        // SIGNUP MODE: User must NOT fully exist
        if (!user.isNewUser && user.isOnboarded) {
          // User exists and has a role -> Not allowed in Signup Web
          print('❌ [AuthService] Existing user tried to Signup. Blocking.');
          await logout();
          throw 'Account already exists. Please Sign In.';
        }
      }

      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Sign Up with Email & Password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final session = response.session;
      final user = response.user;

      if (user == null) throw 'Sign up failed - no user returned';

      // If email confirmation is enabled, session might be null
      if (session != null) {
        await saveToken(session.accessToken);
      }

      // Sync user with backend (create profile)
      // Note: If email is not confirmed, this might fail depending on RLS.
      // But typically we want to create the profile row.
      try {
        return await syncUser(
          email: email,
          fullName: fullName,
        );
      } catch (e) {
        print('Sync warning: $e');
        // If sync fails but auth worked, return a partial user model
        return UserModel(
          id: user.id,
          email: email,
          fullName: fullName,
          role: null, // Will need to define role later
          isOnboarded: false,
        );
      }
    } catch (e) {
      throw 'Sign Up Failed: $e';
    }
  }

  // Sign In with Email & Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) throw 'Login failed - no active session';

      await saveToken(session.accessToken);

      // Fetch/Sync user
      final user = response.user;
      return await syncUser(
        email: email,
        fullName: user?.userMetadata?['full_name'] ?? 'User',
      );
    } catch (e) {
      throw 'Sign In Failed: ${e.toString().replaceAll("AuthException:", "").trim()}';
    }
  }

  // Send Password Reset Email (OTP)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw 'Reset Password Failed: $e';
    }
  }

  // Verify Recovery OTP
  Future<AuthResponse> verifyRecoveryOtp(String email, String token) async {
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.session != null) {
        await saveToken(response.session!.accessToken);
      }
      return response;
    } catch (e) {
      throw 'Verification Failed: $e';
    }
  }
}
