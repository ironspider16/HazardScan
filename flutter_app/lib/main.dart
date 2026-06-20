import 'package:flutter/material.dart';
import 'package:kkhazardscan/config/language_manager.dart';
import 'pages/login_screen.dart'; // make sure this file is in lib/login_screen.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Design/style_constant.dart';
import 'pages/main_menu.dart';
import 'config/app_users.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kkhazardscan/yolo/yolo_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
        'https://bpknkumrsvuhkobxsvom.supabase.co', // replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwa25rdW1yc3Z1aGtvYnhzdm9tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MTg4OTYsImV4cCI6MjA5Mjk5NDg5Nn0.-Vyj7QvPKAkNcnlPC6OjE_KugMTPgLQyDh2o-0thdNM', // replace with your Supabase anon key
  );
  YoloService().coldStart(); // Call the cold start method for Backend Cloud API
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, currentLocale, child) {
        return MaterialApp(
          title: 'Safety App Login',
          locale: currentLocale,
          supportedLocales: const [Locale('en'), Locale('zh')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.backgroundWhite, // [13, 14]
            // 1. Global AppBar Theme
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.backgroundWhite,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: AppTypography.Blueheading, // [6, 14, 20]
            ),

            // 2. Global Input Decoration (replacing repetitive _inputDecoration methods)
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              prefixIconColor: AppColors.textSecondary,
              suffixIconColor: AppColors.textSecondary,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),

            // 3. Global Button Theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                textStyle: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 4. Global Color Scheme (for widgets like Chips and Progress Indicators)
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              primary: AppColors.primaryBlue,
              surface: AppColors.backgroundWhite,
              secondaryContainer: AppColors.primaryTint, // [4, 8]
            ),
          ),
          home: const InitialAuthGateway(),
        );
      },
    );
  }
}

class InitialAuthGateway extends StatefulWidget {
  const InitialAuthGateway({super.key});

  @override
  State<InitialAuthGateway> createState() => _InitialAuthGatewayState();
}

class _InitialAuthGatewayState extends State<InitialAuthGateway> {
  bool _isResolvingRoute = true;
  bool _deviceIsAuthorizedTech = false;

  @override
  void initState() {
    super.initState();
    _evaluateDeviceAuthorization();
  }

  Future<void> _evaluateDeviceAuthorization() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Step 1: Query browser local storage persistent keys
      bool isRegistered =
          prefs.getBool('is_registered_technician_device') ?? false;

      // Step 2: Fallback query matching active address bar variables
      final Uri currentUri = Uri.base;
      if (currentUri.queryParameters.containsKey('auth')) {
        final String? token = currentUri.queryParameters['auth'];
        if (token ==
            'kkh_secure_gateway_9f8e7d6c5b4a3f2e1_tech_access_production_2026') {
          await prefs.setBool('is_registered_technician_device', true);
          isRegistered = true;
        }
      }

      if (mounted) {
        setState(() {
          _deviceIsAuthorizedTech = isRegistered;
          _isResolvingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolvingRoute = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show static layout element during internal asynchronous storage operations
    if (_isResolvingRoute) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    // Direct routing split paths based on evaluated device authorization context
    if (_deviceIsAuthorizedTech) {
      return MainMenu(
        user: AppUser(
          id: 0,
          email: "technician@example.com",
          password: '',
          role: UserRole.user,
        ),
      );
    }

    return const LoginScreen();
  }
}
