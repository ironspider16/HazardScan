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
  const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase credentials. Ensure --dart-define-from-file=secrets.json is appended.',
    );
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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
  AppUser? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _evaluateDeviceAuthorization();
  }

  Future<void> _evaluateDeviceAuthorization() async {
    final Uri currentUri = Uri.base;
    final Map<String, String> queryParameters = currentUri.queryParameters;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasValidToken = false;
      const String techEmail = String.fromEnvironment(
        'TECH_EMAIL',
        defaultValue: '',
      );
      const String techPassword = String.fromEnvironment(
        'TECH_PASSWORD',
        defaultValue: '',
      );

      const String gatewayToken = String.fromEnvironment(
        'GATEWAY_TOKEN',
        defaultValue: '',
      );

      if (queryParameters.containsKey('auth')) {
        final String? token = queryParameters['auth'];
        if (gatewayToken.isNotEmpty &&
            token == gatewayToken) {
          await prefs.setBool('is_registered_technician_device', true);
          hasValidToken = true;
        }
      }

      bool isRegistered =
          prefs.getBool('is_registered_technician_device') ?? false;

      // Catch configuration oversights immediately
      if (isRegistered && (techEmail.isEmpty || techPassword.isEmpty)) {
        debugPrint(
          'CRITICAL: App recognizes technician device, but credentials are missing from environment.',
        );
      }

      if (isRegistered && techEmail.isNotEmpty && techPassword.isNotEmpty) {
        final Session? currentSession =
            Supabase.instance.client.auth.currentSession;

        // If an admin session is currently active but a technician token was passed, clear it
        if (currentSession != null &&
            currentSession.user.email != techEmail &&
            hasValidToken) {
          await Supabase.instance.client.auth.signOut();
        }

        // Authenticate Technician implicitly in the background
        final AuthResponse res = await Supabase.instance.client.auth
            .signInWithPassword(email: techEmail, password: techPassword);

        if (res.user != null) {
          _authenticatedUser = AppUser(
            id: 0,
            email: res.user!.email!,
            password: '',
            role: UserRole.user,
          );
        }
      } else {
        // Evaluate persistent standalone sessions for administrators
        final Session? currentSession =
            Supabase.instance.client.auth.currentSession;
        if (currentSession != null &&
            (techEmail.isEmpty || currentSession.user.email != techEmail)) {
          _authenticatedUser = AppUser(
            id: 1,
            email: currentSession.user.email!,
            password: '',
            role: UserRole.admin,
          );
        }
      }

      if (mounted) {
        setState(() => _isResolvingRoute = false);
      }
    } catch (e) {
      debugPrint('Authorization error: $e');
      if (mounted) {
        setState(() => _isResolvingRoute = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingRoute) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    if (_authenticatedUser != null) {
      return MainMenu(user: _authenticatedUser!);
    }

    return const LoginScreen();
  }
}
