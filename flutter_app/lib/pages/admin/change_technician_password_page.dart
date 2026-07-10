import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeTechnicianPasswordPage extends StatefulWidget {
  const ChangeTechnicianPasswordPage({super.key});

  @override
  State<ChangeTechnicianPasswordPage> createState() =>
      _ChangeTechnicianPasswordPageState();
}

class _ChangeTechnicianPasswordPageState
    extends State<ChangeTechnicianPasswordPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isChangingPassword = false;

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

  Future<void> _changeTechnicianPassword() async {
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
        'change-technician-password',
        body: {'new_password': _passwordController.text},
      );

      if (response.status < 200 || response.status >= 300) {
        String message = 'Unable to change technician password.';

        if (response.data is Map) {
          message = response.data['error']?.toString() ?? message;
        }

        throw Exception(message);
      }

      if (!mounted) return;

      _passwordController.clear();

      _showMessage('Technician password changed successfully.');
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
      appBar: const UniversalAppBar(title: 'Change Technician Password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.page,
            vertical: 30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 60,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Change Technician Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a new password for the technician account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.engineering_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Technician',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isChangingPassword,
                          obscureText: _hidePassword,
                          validator: _validatePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isChangingPassword) {
                              _changeTechnicianPassword();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'New Technician Password',
                            hintText: 'Enter the new password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: _isChangingPassword
                                  ? null
                                  : () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isChangingPassword
                                ? null
                                : _changeTechnicianPassword,
                            icon: _isChangingPassword
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset),
                            label: Text(
                              _isChangingPassword
                                  ? 'Changing Password...'
                                  : 'Change Password',
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
