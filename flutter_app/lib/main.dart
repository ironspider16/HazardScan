import 'package:flutter/material.dart';
import 'pages/login_screen.dart'; // make sure this file is in lib/login_screen.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Design/style_constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
        'https://bpknkumrsvuhkobxsvom.supabase.co', // replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwa25rdW1yc3Z1aGtvYnhzdm9tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MTg4OTYsImV4cCI6MjA5Mjk5NDg5Nn0.-Vyj7QvPKAkNcnlPC6OjE_KugMTPgLQyDh2o-0thdNM', // replace with your Supabase anon key
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App Login',
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
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
      home: const LoginScreen(),
    );
  }
}
