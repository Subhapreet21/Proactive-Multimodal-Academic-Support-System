import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    print('📂 Loading .env file...');
    await dotenv.load(fileName: '.env');
    print('✅ .env loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    // Initialize with empty map to avoid NotInitializedError
    dotenv.testLoad(fileInput: '');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    print('✅ Supabase initialized');
  } catch (e) {
    print('⚠️ Warning: Could not initialize Supabase: $e');
  }

  runApp(const CampusAssistantApp());
}

class CampusAssistantApp extends StatefulWidget {
  const CampusAssistantApp({super.key});

  @override
  State<CampusAssistantApp> createState() => _CampusAssistantAppState();
}

class _CampusAssistantAppState extends State<CampusAssistantApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Use a global key or context if available to navigate
        // Since we are in main, we might need a GlobalKey<NavigatorState>
        // But assuming GoRouter is used, we can redirect via router logic or basic navigation
        // For simplicity here, let's just print. The Router should handle this if we set up a redirect.
        // Wait, GoRouter 'redirect' logic usually checks auth state.
        // But for password recovery, we explicitly want to go to /reset-password.

        // Let's rely on the Router redirect logic in `routes.dart` to handle this if possible,
        // OR use a GlobalKey for the navigator.
        // The AppRouter probably listens to AuthProvider.
        // Let's update AuthProvider to handle this event.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Campus OS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router(authProvider),
          );
        },
      ),
    );
  }
}
