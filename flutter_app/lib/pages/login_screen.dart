import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_users.dart';
import '../pages/main_menu.dart';
import 'package:kkhazardscan/supabase_client.dart';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';
import '../widgets/App_Textfield.dart';
import 'camera_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception("Login failed. No user found.");
      }

      final roleResponse = await supabase.functions.invoke('get-user-role');

      final data = roleResponse.data;

      final String role = data['role'];

      final UserRole userRole = role == 'admin'
          ? UserRole.admin
          : UserRole.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);

      final AppUser loggedInUser = AppUser(
        id: 0, // dummy ID because you removed id from accounts table
        email: data['email'],
        password: '',
        role: userRole,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainMenu(user: loggedInUser)),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // login_screen.dart
  @override
  Widget build(BuildContext context) {
    // Use your standardized padding/dimensions
    final double fieldWidth = (MediaQuery.of(context).size.width * 0.85).clamp(
      300.0,
      450.0,
    );

    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFF2563EB),
      //   onPressed: () async {
      //     final result = await Navigator.push<Map<String, dynamic>?>(
      //       context,
      //       MaterialPageRoute(builder: (_) => const CameraPage()),
      //     );

      //     if (result == null) return;
      //   },
      //   child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      // ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.page),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Icon_kkh_512.png',
                    width: 100,
                    height: 100,
                  ),

                  const SizedBox(height: AppPadding.medium),

                  Text("HazardScan", style: AppTypography.Blueheading),

                  const SizedBox(height: AppPadding.tight),

                  Text("Sign in to continue", style: AppTypography.faintbody),

                  const SizedBox(height: AppPadding.extraLarge),

                  // EMAIL FIELD
                  SizedBox(
                    width: fieldWidth,
                    child: AppTextfield(
                      controller: _emailCtrl,
                      label: "Email",
                      hint: "Email Address",
                      prefixIcon: Icons.email_outlined,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Email is required" : null,
                    ),
                  ),

                  const SizedBox(height: AppPadding.medium),

                  // PASSWORD FIELD
                  SizedBox(
                    width: fieldWidth,
                    child: AppTextfield(
                      controller: _passwordCtrl,
                      label: "Password",
                      hint: "Password",
                      obscureText: !_showPassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? "Password is required"
                          : null,
                    ),
                  ),

                  const SizedBox(height: AppPadding.large),

                  // LOGIN BUTTON
                  SizedBox(
                    width: fieldWidth,
                    child: MenuButton(
                      label: _isLoading ? "Logging in..." : "Login",
                      onTap: _isLoading ? () => {} : _login,
                      isPrimary: true,
                      icon: Icons.login,
                    ),
                  ),
                  const SizedBox(height: AppPadding.tight / 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
