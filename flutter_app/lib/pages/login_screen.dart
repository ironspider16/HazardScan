import 'package:flutter/material.dart';
import '../config/app_users.dart';
import '../pages/main_menu.dart';
import 'package:flutter_application_1/supabase_client.dart';

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

  InputDecoration _inputStyle({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3366CC), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔷 ICON
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_hospital, // or Icons.medical_services
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 20),
                // 🔥 TITLE
                const Text(
                  "HazardScan",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Sign in to continue",
                  style: TextStyle(fontSize: 15, color: Color(0xFF6F6F6F)),
                ),

                const SizedBox(height: 50),

                // EMAIL
                SizedBox(
                  width: width,
                  height: 70,
                  child: TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(fontSize: 15),
                    decoration: _inputStyle(
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Email is required";
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // PASSWORD
                SizedBox(
                  width: width,
                  height: 70,
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    style: const TextStyle(fontSize: 15),
                    decoration: _inputStyle(
                      hint: "Enter your password",
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                          color: const Color.fromARGB(255, 81, 81, 81),
                        ),
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Password is required";
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // BUTTON
                SizedBox(
                  width: width,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
