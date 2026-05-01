import 'package:flutter/material.dart';
import '../../services/accounts_file_service.dart';
import 'package:flutter_application_1/supabase_client.dart';

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
      final newLine = "$email,$password,$role";

      final oldText = await AccountsFileService.instance.loadRaw();
      final updatedText = oldText.trim().isEmpty
          ? newLine
          : "${oldText.trim()}\n$newLine";

      await AccountsFileService.instance.saveRaw(updatedText);

      await supabase.from('accounts').upsert({
        'email': email,
        'password': password,
        'role': role,
        'name': name,
      }, onConflict: 'email');

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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),

      // 👇 DEFAULT BORDER
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 136, 136, 136), // dark grey
          width: 1,
        ),
      ),

      // 👇 WHEN CLICKED (FOCUSED)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 77, 77, 77), // darker when active
          width: 2,
        ),
      ),

      // 👇 ERROR STATE (optional)
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        SizedBox(
          height: 50,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: _inputDecoration(hint),
          ),
        ),
      ],
    );
  }

  Widget _roleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Role"),
        SizedBox(
          height: 50,
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: _inputDecoration("Role"),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            dropdownColor: Colors.white,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 16, 23, 30),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      "Add Users",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 82),

              _textField(
                label: "Technician Email",
                hint: "worker1@example.com",
                controller: _emailCtrl,
              ),

              const SizedBox(height: 28),

              _textField(
                label: "Password",
                hint: "********",
                controller: _passwordCtrl,
                obscureText: false,
              ),

              const SizedBox(height: 28),

              _textField(
                label: "Name",
                hint: "Johnathan",
                controller: _nameCtrl,
              ),

              const SizedBox(height: 28),

              _roleDropdown(),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canSubmit ? _addUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color.fromARGB(
                      255,
                      135,
                      166,
                      233,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Add User",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
