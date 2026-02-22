import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/user_main_screen.dart';
import 'screens/coordinator/coordinator_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const EventPanelApp(),
    ),
  );
}

class EventPanelApp extends StatefulWidget {
  const EventPanelApp({super.key});

  @override
  State<EventPanelApp> createState() => _EventPanelAppState();
}

class _EventPanelAppState extends State<EventPanelApp> {
  @override
  void initState() {
    super.initState();
    // Load user profile if already logged in (on app start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          title: 'EventPanel',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: _getHomeScreen(authProvider),
        );
      },
    );
  }

  Widget _getHomeScreen(AuthProvider authProvider) {
    // Show loading while checking auth state
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Not authenticated - show login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated - show appropriate dashboard
    if (authProvider.isCoordinator) {
      return const CoordinatorMainScreen();
    } else {
      return const UserMainScreen();
    }
  }
}

