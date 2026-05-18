import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import '../../widgets/Menu_button.dart';
import '../../Design/style_constant.dart';
import '../../widgets/App_Textfield.dart';

class EditAccountsPage extends StatefulWidget {
  final Map<String, dynamic> account;
  const EditAccountsPage({super.key, required this.account});

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String? _selectedRole;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Fill the controllers with existing data
    _emailCtrl.text = widget.account['email'] ?? '';
    _nameCtrl.text = widget.account['name'] ?? '';
    _passwordCtrl.text = widget.account['password'] ?? '';
    _selectedRole = widget.account['role'];
  }

  Future<void> _updateUser() async {
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
      await supabase
          .from('accounts')
          .update({
            'email': email,
            'password': password,
            'role': role,
            'name': name,
          })
          .eq('id', widget.account['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User updated successfully")),
      );

      Navigator.pop(context); // Go back after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating user: $e"),
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
        Text(
          "Role",
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppPadding.tight),
        SizedBox(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textMain,
            ),
            style: AppTypography.body,
            decoration: const InputDecoration(hintText: "Select Role"),
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
        title: const Text("Edit User", style: AppTypography.Bluesubheading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.page),
          child: Column(
            children: [
              Expanded(
                // Use Expanded + SingleChildScrollView to prevent keyboard overflow
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
                label: _saving ? "Updating..." : "Update User",
                onTap: _saving ? () {} : _updateUser,
                isPrimary: true,
                icon: Icons.update, // Save icon for update action
              ),
            ],
          ),
        ),
      ),
    );
  }
}
