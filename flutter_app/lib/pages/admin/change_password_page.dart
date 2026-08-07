import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Menu_button.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isChangingPassword = false;
  String selectedRole = 'Admin';
  final List<String> roles = ['Admin', 'Technician'];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }

    return null;
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        throw const AuthException('Admin is not logged in.');
      }

      final response = await _supabase.functions.invoke(
        'change-password',
        body: {
          'new_password': _passwordController.text,
          'role': selectedRole.toLowerCase(),
        },
      );

      if (response.status < 200 || response.status >= 300) {
        String message = 'Unable to change $selectedRole password.';

        if (response.data is Map) {
          message = response.data['error']?.toString() ?? message;
        }

        throw Exception(message);
      }

      if (!mounted) return;

      _passwordController.clear();

      _showMessage('$selectedRole password changed successfully.');
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: const UniversalAppBar(title: 'Change Password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.page,
            vertical: AppPadding.tight,
          ),
          child: Card(
            color: AppColors.primaryTint,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: AppPadding.Largest,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppPadding.tight),
                    const Text(
                      'Change Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppPadding.tight),
                    const Text(
                      'Enter a new password for the technician or admin account.',
                      style: AppTypography.faintbody,
                    ),
                    const SizedBox(height: AppPadding.medium),
                    DropdownMenu<String>(
                      requestFocusOnTap: false,
                      expandedInsets: EdgeInsets.zero,
                      initialSelection: selectedRole,
                      onSelected: (String? newValue) {
                        setState(() {
                          selectedRole = newValue ?? 'Admin';
                        });
                      },
                      dropdownMenuEntries: roles.map<DropdownMenuEntry<String>>(
                        (String value) {
                          return DropdownMenuEntry<String>(
                            value: value,
                            label: value,
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: AppPadding.tight),
                    AppTextfield(
                      label: '',
                      islabel: false,
                      controller: _passwordController,
                      hint: "New $selectedRole Password",
                      obscureText: _hidePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppPadding.medium),
                    MenuButton(
                      label: "Change password",
                      isPrimary: true,
                      icon: _isChangingPassword
                          ? Icons.hourglass_empty
                          : Icons.lock_reset,
                      onTap: () {
                        if (!_isChangingPassword) {
                          _changePassword();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
