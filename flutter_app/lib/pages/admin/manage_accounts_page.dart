import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/admin/edit_accounts_page.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'add_accounts_page.dart'; 
import '../../widgets/Menu_button.dart';

class ManageAccountsPage extends StatefulWidget {
  const ManageAccountsPage({super.key});

  @override
  State<ManageAccountsPage> createState() => _ManageAccountsPageState();
}

class _ManageAccountsPageState extends State<ManageAccountsPage> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  // 1. Get data from Supabase
  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('accounts')
          .select()
          .order('name', ascending: true);
      setState(() => _accounts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching accounts: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> account) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: Text("Are you sure you want to delete ${account['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('accounts').delete().eq('email', account['email']);
      _fetchAccounts(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Worker Accounts",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // List of Accounts
                  Expanded(
                    child: ListView.separated(
                      itemCount: _accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final acc = _accounts[index];
                        return _AccountRow(
                          name: acc['name'] ?? 'No Name',
                          role: acc['role'] ?? 'User',
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditAccountsPage(account: acc),
                              ),
                            );
                            _fetchAccounts(); // Refresh when coming back
                          },
                          onDelete: () => _confirmDelete(acc),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(height: 40, thickness: 1, color: Color(0xFFE0E0E0)),

                  // Add Users Button
                  _AddUserButton(onTap: () async {
                    // Navigate to your existing Add User page
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAccountsPage()),
                    );
                    _fetchAccounts(); // Refresh when coming back
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _AccountRow extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountRow({
    required this.name,
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(22, 37, 100, 235), // Light blue tint
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$name | $role",
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black87),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// Custom Add User Button Widget
class _AddUserButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddUserButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add User",
      icon: Icons.person_add_alt,
      onTap: onTap,
      // Custom styling for the button
    );
  }
}