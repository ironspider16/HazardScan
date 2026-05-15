import 'package:flutter/material.dart';
import '../config/app_users.dart';
import '../pages/main_menu.dart';
import 'package:kkhazardscan/supabase_client.dart';
import '../Design/style_constant.dart';
import '../widgets/Menu_button.dart';
import '../widgets/App_Textfield.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final data = await supabase
          .from('accounts')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (!mounted) return;
      setState(() => _loading = false);

      if (data != null) {
        final roleFromDb = data['role'].toString();

        final role = roleFromDb == 'Administrator'
            ? UserRole.admin
            : UserRole.user;

        final user = AppUser(
          id: data['id'] as int,
          email: data['email'].toString(),
          password: data['password'].toString(),
          role: role,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenu(user: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>?>(
            context,
            MaterialPageRoute(builder: (_) => const CameraPage()),
          );

          if (result == null) return;
        },
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.page),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/KKHlogo.svg',
                    width: 100,
                    height: 100,
                    semanticsLabel: 'Company Logo',
                  ),

                  const SizedBox(height: AppPadding.medium),

                  // 🔥 TITLE (Using Typography Class)
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
                      label: _loading ? "Logging in..." : "Login",
                      onTap: _loading ? () => {} : _handleLogin,
                      isPrimary: true,
                      icon: Icons.login,
                    ),
                  ),
                  const SizedBox(height: AppPadding.tight),
                  SizedBox(
                    width: fieldWidth,
                    child: MenuButton(
                      label: _loading
                          ? "Logging in..."
                          : "Continue as Technician",
                      onTap: _loading ? () => {} : _handleLogin,
                      isPrimary: true,
                      icon: Icons.person_3_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
