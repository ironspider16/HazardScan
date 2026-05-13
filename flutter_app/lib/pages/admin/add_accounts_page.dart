import 'package:flutter/material.dart';
import '../../services/accounts_file_service.dart';
import 'package:flutter_application_1/supabase_client.dart';
import '../../widgets/Menu_button.dart';
import '../../Design/style_constant.dart';
import '../../main.dart';
import '../../widgets/App_Textfield.dart';

class AddAccountsPage extends StatefulWidget {
  const AddAccountsPage({super.key});

  @override
  State<AddAccountsPage> createState() => _AddAccountsPageState();
}

class _AddAccountsPageState extends State<AddAccountsPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String? _selectedRole;
  bool _saving = false;

  Future<void> _addUser() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final role = _selectedRole;

    if (email.isEmpty || password.isEmpty || name.isEmpty || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _saving = true);

    try {

      await supabase.from('accounts').insert({
        'email': email,
        'password': password,
        'role': role,
        'name': name,
      }, );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User added successfully")));

      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nameCtrl.clear();
      setState(() => _selectedRole = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding user: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

    Widget _roleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Role", style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppPadding.tight),
        SizedBox(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMain),
            style: AppTypography.body,
            decoration: const InputDecoration(
              hintText: "Select Role",
            ),
            items: const [
              DropdownMenuItem(value: "Technician", child: Text("Technician")),
              DropdownMenuItem(value: "Administrator", child: Text("Admin")),
            ],
            onChanged: (value) {
              setState(() => _selectedRole = value);
            },
          ),
        ),
      ],
    );
  }

    @override
  Widget build(BuildContext context) {
    final canSubmit = !_saving;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // Using a standard AppBar for coherence with the previous page
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add User", style: AppTypography.Bluesubheading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.page),
          child: Column(
            children: [
              Expanded( // Use Expanded + SingleChildScrollView to prevent keyboard overflow
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppPadding.large),
                      
                      AppTextfield(
                        label: "Technician Email",
                        hint: "worker1@example.com",
                        controller: _emailCtrl,
                        enabled: true, 
                      ),

                      const SizedBox(height: AppPadding.medium),

                      AppTextfield(
                        label: "Password",
                        hint: "Enter new password",
                        controller: _passwordCtrl,
                        enabled: true,
                      ),

                      const SizedBox(height: AppPadding.medium),

                      AppTextfield(
                        label: "Full Name",
                        hint: "e.g. Johnathan Doe",
                        controller: _nameCtrl,
                        enabled: true,
                      ),

                      const SizedBox(height: AppPadding.medium),

                      _roleDropdown(),
                    ],
                  ),
                ),
              ),

              // Submit Button stays at the bottom
              const SizedBox(height: AppPadding.medium),
              MenuButton(
                label: _saving ? "Adding..." : "Add User",
                onTap: _saving ? () {} : _addUser,
                isPrimary: true,
                icon: Icons.add, // Save icon for add action
              ),
            ],
          ),
        ),
      ),
    );
  }
}
