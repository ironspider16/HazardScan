import 'package:flutter/material.dart';
import 'pages/login_screen.dart'; // make sure this file is in lib/login_screen.dart
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bpknkumrsvuhkobxsvom.supabase.co',// replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwa25rdW1yc3Z1aGtvYnhzdm9tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MTg4OTYsImV4cCI6MjA5Mjk5NDg5Nn0.-Vyj7QvPKAkNcnlPC6OjE_KugMTPgLQyDh2o-0thdNM', // replace with your Supabase anon key
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 239, 13, 1), // blue-600 tone
        ),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
