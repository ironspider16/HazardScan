import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageImmediateEmailsPage extends StatefulWidget {
  const ManageImmediateEmailsPage({super.key});

  @override
  State<ManageImmediateEmailsPage> createState() => _ManageImmediateEmailsPageState();
}

class _ManageImmediateEmailsPageState extends State<ManageImmediateEmailsPage> {
  List<Map<String, dynamic>> _emails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  // 1. Get data from Supabase
  Future<void> _fetchEmails() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('immediate_emails')
          .select()
          .order('email', ascending: true);
      setState(() => _emails = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching immediate emails: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Open adaptive dialog to handle both Adding and Editing actions
  Future<void> _showEmailDialog({
    Map<String, dynamic>? emailToEdit,
  }) async {
    final bool isEdit = emailToEdit != null;
    final TextEditingController controller = TextEditingController(
      text: isEdit ? emailToEdit['email'] : '',
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          isEdit ? "Edit Email" : "Add Email",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: AppTextfield(
          label: '',
          islabel: false,
          hint: "Enter email address",
          controller: controller,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: MenuButton(
                  onTap: () => Navigator.pop(ctx, false),
                  label: "Cancel",
                  height: 44,
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  isPrimary: true,
                  onTap: () => Navigator.pop(ctx, true),
                  label: isEdit ? "Save" : "Add",
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Process implementation if confirmed and string data is not empty
    if (shouldSave == true && controller.text.trim().isNotEmpty) {
      final String inputName = controller.text.trim();
      setState(() => _isLoading = true);

      try {
        if (isEdit) {
          // Update database entry matching the original name context
          await supabase
              .from('immediate_emails')
              .update({'email': inputName})
              .eq('email', emailToEdit['email']);
        } else {
          // Insert completely new entry row
          await supabase.from('immediate_emails').insert({'email': inputName});
        }
        _fetchEmails();
      } catch (e) {
        debugPrint("Error processing database query: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> email) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "Delete Email?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${email['email']}?",
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: AppTypography.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: AppTypography.body.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase
          .from('immediate_emails')
          .delete()
          .eq('email', email['email']);
      _fetchEmails(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage Immediate Emails"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of Emails
                  Expanded(
                    child: ListView.separated(
                      itemCount: _emails.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppPadding.tight),
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        return _EmailRow(
                          email: email['email'] ?? 'No Email',
                          onEdit: () =>
                              _showEmailDialog(emailToEdit: email),
                          onDelete: () => _confirmDelete(email),
                        );
                      },
                    ),
                  ),

                  const Divider(
                    height: AppPadding.large,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),

                  // Add Emails Button
                  _AddEmailButton(onTap: () => _showEmailDialog()),
                  const SizedBox(height: AppPadding.medium),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _EmailRow extends StatelessWidget {
  final String email;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmailRow({
    required this.email,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.tight,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint, // Light blue tint
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(child: Text(email, style: AppTypography.body)),
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

// Custom Add Email Button Widget
class _AddEmailButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddEmailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add Email",
      icon: Icons.email,
      onTap: onTap,
      // Custom styling for the button
    );
  }
}
