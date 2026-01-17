import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
  static String get clerkPublishableKey => dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '';
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
