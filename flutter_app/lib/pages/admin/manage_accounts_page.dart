import 'package:flutter/material.dart';
import 'package:flutter_application_1/Design/style_constant.dart';
import 'package:flutter_application_1/pages/admin/edit_accounts_page.dart';
import 'package:flutter_application_1/supabase_client.dart';
import 'add_accounts_page.dart'; 
import '../../widgets/Menu_button.dart';
import '../../Design/style_constant.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: Text("Delete Account?", style: AppTypography.Blackheading.copyWith(fontSize: 24,color: Colors.red)),
        content: Text("Are you sure you want to delete ${account['name']}?", style: AppTypography.body.copyWith(fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text("Cancel", style: AppTypography.body)
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text("Delete", style: AppTypography.body.copyWith(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm == true) {
      await supabase.from('accounts').delete().eq('email', account['email']);
      _fetchAccounts(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Worker Accounts",
          style: AppTypography.Bluesubheading,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of Accounts
                  Expanded(
                    child: ListView.separated(
                      itemCount: _accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppPadding.tight),
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
                  
                  const Divider(height: AppPadding.large, thickness: 1, color: Color(0xFFE0E0E0)),

                  // Add Users Button
                  _AddUserButton(onTap: () async {
                    // Navigate to your existing Add User page
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAccountsPage()),
                    );
                    _fetchAccounts(); // Refresh when coming back
                  }),
                  const SizedBox(height: AppPadding.medium),
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
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium, vertical: AppPadding.tight),
      decoration: BoxDecoration(
        color: AppColors.primaryTint, // Light blue tint
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$name | $role",
              style: AppTypography.body,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppColors.textMain),
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