import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_strings.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_activity_screen.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/my_activities_screen.dart';
import 'screens/aadhaar_scan_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  
  runApp(const JoinMeApp());
}

class JoinMeApp extends StatelessWidget {
  const JoinMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/create-activity': (context) => const CreateActivityScreen(),
              '/my-activities': (context) => const MyActivitiesScreen(),
              '/aadhaar-scan': (context) => const AadhaarScanScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle /activity/:id route
              if (settings.name?.startsWith('/activity/') ?? false) {
                final activityId = settings.name!.split('/activity/').last;
                return MaterialPageRoute(
                  builder: (context) => ActivityDetailScreen(activityId: activityId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Wrapper widget that checks auth state and shows appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show home if authenticated, login if not
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

