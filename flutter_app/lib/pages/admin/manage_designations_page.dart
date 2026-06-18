import 'package:flutter/material.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageDesignationsPage extends StatefulWidget {
  const ManageDesignationsPage({super.key});

  @override
  State<ManageDesignationsPage> createState() => _ManageDesignationsPageState();
}

class _ManageDesignationsPageState extends State<ManageDesignationsPage> {
  List<Map<String, dynamic>> _designations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDesignations();
  }

  // 1. Get data from Supabase
  Future<void> _fetchDesignations() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('designations')
          .select()
          .order('designation', ascending: true);
      setState(() => _designations = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching designations: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Open adaptive dialog to handle both Adding and Editing actions
  Future<void> _showDesignationDialog({
    Map<String, dynamic>? designationToEdit,
  }) async {
    final bool isEdit = designationToEdit != null;
    final TextEditingController controller = TextEditingController(
      text: isEdit ? designationToEdit['designation'] : '',
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          isEdit ? "Edit Designation" : "Add Designation",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: AppTextfield(
          label: '',
          islabel: false,
          hint: "Enter designation name",
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
                  height: 44
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
              .from('designations')
              .update({'designation': inputName})
              .eq('designation', designationToEdit['designation']);
        } else {
          // Insert completely new entry row
          await supabase.from('designations').insert({'designation': inputName});
        }
        _fetchDesignations();
      } catch (e) {
        debugPrint("Error processing database query: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> designation) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Text(
          "Delete Designation?",
          style: AppTypography.Blackheading.copyWith(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${designation['designation']}?",
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
          .from('designations')
          .delete()
          .eq('designation', designation['designation']);
      _fetchDesignations(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: UniversalAppBar(title: "Manage Designations"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.page),
              child: Column(
                children: [
                  const SizedBox(height: AppPadding.medium),
                  // List of Designations 
                  Expanded(
                    child: ListView.separated(
                      itemCount: _designations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppPadding.tight),
                      itemBuilder: (context, index) {
                        final designation = _designations[index];
                        return _DesignationRow(
                          designation: designation['designation'] ?? 'No Designation',
                          onEdit: () =>
                              _showDesignationDialog(designationToEdit: designation),
                          onDelete: () => _confirmDelete(designation),
                        );
                      },
                    ),
                  ),

                  const Divider(
                    height: AppPadding.large,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),

                  // Add Designations Button
                  _AddDesignationButton(onTap: () => _showDesignationDialog()),
                  const SizedBox(height: AppPadding.medium),
                ],
              ),
            ),
    );
  }
}

// Custom Row Widget based on Figma
class _DesignationRow extends StatelessWidget {
  final String designation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesignationRow({
    required this.designation,
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
          Expanded(child: Text(designation, style: AppTypography.body)),
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

// Custom Add Designation Button Widget
class _AddDesignationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddDesignationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      label: "Add Designation",
      icon: Icons.people,

      onTap: onTap,
      // Custom styling for the button
    );
  }
}
